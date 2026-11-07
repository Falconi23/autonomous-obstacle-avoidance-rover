% ROVER_REMOTE_CONTROL  Arrow-key drive (F/B/L/R, S on release) with live "motor1,motor2" plots.
% Extracted from the Live Script RadicomandoWithArduinoV4.0.mlx. Close the figure to stop.

port = "COM5";
baudRate = 9600;

% Release ports left open by a previous run.
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

s = serialport(port, baudRate);

hFig = figure('Name', 'Robot Control', 'NumberTitle', 'off', ...
              'KeyPressFcn', @(src, event) keyPress(src, event, s), ...
              'KeyReleaseFcn', @(src, event) keyRelease(src, event, s), ...
              'CloseRequestFcn', @(src, event) closeFigure(src, event, s));

ax1 = subplot(2, 1, 1);
hLine1 = plot(ax1, NaN, NaN);
title(ax1, 'Motor 1 level');
xlabel(ax1, 'Time (s)');
ylabel(ax1, 'Rotations');

ax2 = subplot(2, 1, 2);
hLine2 = plot(ax2, NaN, NaN);
title(ax2, 'Motor 2 level');
xlabel(ax2, 'Time (s)');
ylabel(ax2, 'Rotations');

% Window-level callbacks so keys are caught even when an axes has focus.
set(hFig, 'WindowKeyPressFcn', @(src, event) keyPress(src, event, s));
set(hFig, 'WindowKeyReleaseFcn', @(src, event) keyRelease(src, event, s));

updateInterval = 0.1; % [s]
t = timer('ExecutionMode', 'fixedRate', 'Period', updateInterval, ...
          'TimerFcn', @(~, ~) updatePlot(s, hLine1, hLine2, ax1, ax2));
start(t);

uiwait(hFig);

function keyPress(~, event, s)
    disp(['Key pressed: ', event.Key]);
    switch event.Key
        case 'uparrow'
            s.UserData.upPressTime = tic;
            writeline(s, 'F');
        case 'downarrow'
            s.UserData.downPressTime = tic;
            writeline(s, 'B');
        case 'leftarrow'
            s.UserData.leftPressTime = tic;
            writeline(s, 'L');
        case 'rightarrow'
            s.UserData.rightPressTime = tic;
            writeline(s, 'R');
        otherwise
            disp('Unsupported command');
    end
end

function keyRelease(~, event, s)
    disp(['Key released: ', event.Key]);
    switch event.Key
        case 'uparrow'
            if isfield(s.UserData, 'upPressTime')
                upPressDuration = toc(s.UserData.upPressTime);
                disp(['Key "uparrow" pressed for ', num2str(upPressDuration), ' seconds']);
                s.UserData = rmfield(s.UserData, 'upPressTime');
            end
            writeline(s, 'S');
        case 'downarrow'
            if isfield(s.UserData, 'downPressTime')
                downPressDuration = toc(s.UserData.downPressTime);
                disp(['Key "downarrow" pressed for ', num2str(downPressDuration), ' seconds']);
                s.UserData = rmfield(s.UserData, 'downPressTime');
            end
            writeline(s, 'S');
        case 'leftarrow'
            if isfield(s.UserData, 'leftPressTime')
                leftPressDuration = toc(s.UserData.leftPressTime);
                disp(['Key "leftarrow" pressed for ', num2str(leftPressDuration), ' seconds']);
                s.UserData = rmfield(s.UserData, 'leftPressTime');
            end
            writeline(s, 'S');
        case 'rightarrow'
            if isfield(s.UserData, 'rightPressTime')
                rightPressDuration = toc(s.UserData.rightPressTime);
                disp(['Key "rightarrow" pressed for ', num2str(rightPressDuration), ' seconds']);
                s.UserData = rmfield(s.UserData, 'rightPressTime');
            end
            writeline(s, 'S');
    end
end

function closeFigure(~, ~, s)
    stop(timerfind);
    delete(timerfind);
    clear s;
    delete(gcf);
end

function updatePlot(s, hLine1, hLine2, ax1, ax2)
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
        if length(values) == 2
            motor1Speed = values(1);
            motor2Speed = values(2);

            currentTime = datetime('now') - startTime;
            t(end+1) = seconds(currentTime);
            motor1Data(end+1) = motor1Speed;
            motor2Data(end+1) = motor2Speed;

            set(hLine1, 'XData', t, 'YData', motor1Data);
            set(hLine2, 'XData', t, 'YData', motor2Data);

            ax1.XLim = [max(0, t(end)-10) t(end)];
            ax2.XLim = [max(0, t(end)-10) t(end)];
            drawnow;
        end
    end
end
