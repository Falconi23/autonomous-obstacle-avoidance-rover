% ROVER_OBSTACLE_TELEMETRY  Live motor plots from "motor1,motor2,distance" serial lines.
% Extracted from the Live Script AvoidingObstacleV2.0.mlx. Close the figure to stop.

port = "COM5";
baudRate = 9600;

% Release ports left open by a previous run.
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

s = serialport(port, baudRate);

hFig = figure('Name', 'Robot Control', 'NumberTitle', 'off', ...
              'CloseRequestFcn', @(src, event) closeFigure(src, event, s));

ax1 = subplot(2, 1, 1);
hLine1 = plot(ax1, NaN, NaN);
title(ax1, 'Motor 1 speed');
xlabel(ax1, 'Time (s)');
ylabel(ax1, 'Speed');

ax2 = subplot(2, 1, 2);
hLine2 = plot(ax2, NaN, NaN);
title(ax2, 'Motor 2 speed');
xlabel(ax2, 'Time (s)');
ylabel(ax2, 'Speed');

updateInterval = 0.1; % [s]
t = timer('ExecutionMode', 'fixedRate', 'Period', updateInterval, ...
          'TimerFcn', @(~, ~) updatePlot(s, hLine1, hLine2, ax1, ax2, hFig));
start(t);

uiwait(hFig);

function closeFigure(~, ~, s)
    stop(timerfind);
    delete(timerfind);
    clear s;
    delete(gcf);
end

function updatePlot(s, hLine1, hLine2, ax1, ax2, hFig)
    persistent t motor1Data motor2Data startTime
    if isempty(t)
        t = [];
        motor1Data = [];
        motor2Data = [];
        startTime = datetime('now');
    end

    if s.NumBytesAvailable > 0
        data = readline(s);
        values = str2double(split(data, ','));

        if length(values) == 3 % drop partial lines
            motor1Speed = values(1);
            motor2Speed = values(2);
            distance = values(3);

            currentTime = datetime('now') - startTime;
            t(end+1) = seconds(currentTime);
            motor1Data(end+1) = motor1Speed;
            motor2Data(end+1) = motor2Speed;

            set(hLine1, 'XData', t, 'YData', motor1Data);
            set(hLine2, 'XData', t, 'YData', motor2Data);

            % Same 15 cm threshold as the firmware. pause() stalls this callback for 1 s.
            if distance <= 15
                set(hFig, 'Color', 'red');
                pause(1);
                set(hFig, 'Color', 'white');
            end

            ax1.XLim = [max(0, t(end)-10) t(end)];
            ax2.XLim = [max(0, t(end)-10) t(end)];
            ax1.YLim = [-300 300];
            ax2.YLim = [-300 300];
            drawnow;
        end
    end
end
