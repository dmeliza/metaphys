function [] = DataHandler(obj, event)
%
% DATAHANDLER Handles dispersing data to subscribers
%
% DATAHANDLER is called by the DAQ driver when there is data to be
% processed.  It runs through the list of subscribers, figures out who
% wants what data, and passes data packets to the subscribing functions.
%
% DATAHANDLER also handles calling telegraph handling functions; if scaling
% on channels is set correctly before calling getdata, the data will have
% that scaling. However, because the 'Units' property is read-only during
% acquisition, we have to set that value in the data packet by hand, which
% means UpdateTelegraph needs to return its results in a parseable form.
%
% $Id: DataHandler.m,v 1.5 2006/01/20 22:02:28 meliza Exp $

global mpctrl


% get the subscribers (direct through mpctrl for speed)
if isstruct(mpctrl.subscriber)
    % handle telegraph data
    telegraph_results = UpdateTelegraph;
    % retrieve the data, if there is any. This behavior is going to change
    % according to the type of event
    switch event.Type
        case 'SamplesAcquired'
            avail            = get(obj,'SamplesAcquiredFcnCount');
            [data, time, abstime]   = getdata(obj, avail);
        otherwise
            avail            = get(obj,'SamplesAvailable');
            if avail > 0
                [data, time, abstime]   = getdata(obj, avail);
            else
                [data, time, abstime]   = deal([]);
            end
    end
    daqname     = obj.Name;

    clients = GetSubscriberNames;
    for i = 1:length(clients);
        % start with the default packet
        packet  = packet_struct;

        client              = mpctrl.subscriber.(clients{i});
        packet.name         = client.name;
        packet.instrument   = client.instrument;
        packet.message      = event;
        % if the instrument or data is empty we send an empty packet
        if ~isempty(client.instrument) && ~isempty(data)
            [ind chan]          = GetChannelIndices(client.instrument, daqname);
            if ~isempty(ind)
                packet.channels = CellWrap(chan);
                packet.units    = CellWrap(obj.Channel(ind).Units);
                packet.data     = data(:,ind);
                packet.time     = (time - time(1)) * 1000;  % convert to ms
                packet.timestamp= datenum(abstime);
            end
        end
        % change the units according to telegraph data
        if ~isempty(telegraph_results) && ...
            isfield(telegraph_results, packet.instrument)
            channels    = {telegraph_results.(packet.instrument).channel};
            for j = 1:length(channels)
                ind = strmatch(channels{j}, packet.channels);
                if ~isempty(ind)
                    packet.units{ind(1)} =...
                        telegraph_results.(packet.instrument)(j).units;
                end
            end
        end
        % send the packet
        try
            client.fhandle(packet, client.fargs{:})
        catch
            le  = lasterror;
            DebugPrint('Error calling subscriber %s function:\n%s',...
                        client.name, le.message)
        end
    end
else
    DebugPrint('Data received; no subscriptions.')
    daqcallback(obj, event)
end