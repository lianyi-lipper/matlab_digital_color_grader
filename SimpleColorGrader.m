function SimpleColorGrader()
    % Create the main figure
    hFig = figure('Name', 'Simple Digital Color Grader', ...
                  'Position', [100 100 820 500], ...
                  'NumberTitle', 'off', ...
                  'MenuBar', 'none', ...
                  'Resize', 'off');

    % Create data structure to hold handles and images
    handles.OriginalImage = [];
    handles.CurrentImage = [];

    % Create UI Panels
    hOriginalPanel = uipanel(hFig, 'Title', 'Original Image', 'Position', [0.025 0.24 0.46 0.72]);
    hPreviewPanel = uipanel(hFig, 'Title', 'Preview', 'Position', [0.515 0.24 0.46 0.72]);

    % Create Axes
    handles.OriginalAxes = axes('Parent', hOriginalPanel, 'Position', [0 0 1 1]);
    handles.PreviewAxes = axes('Parent', hPreviewPanel, 'Position', [0 0 1 1]);
    axis(handles.OriginalAxes, 'off');
    axis(handles.PreviewAxes, 'off');

    % Create Buttons
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Load Image', ...
              'Position', [40, 70, 100, 22], ...
              'Callback', @LoadButtonPushed);
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Save Image', ...
              'Position', [160, 70, 100, 22], ...
              'Callback', @SaveButtonPushed);
    handles.ResetButton = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Reset', ...
                                    'Position', [280, 70, 100, 22], ...
                                    'Callback', @ResetButtonPushed);

    % Create Slider and Label
    uicontrol(hFig, 'Style', 'text', 'String', 'Brightness', ...
              'Position', [40, 30, 100, 22]);
    handles.BrightnessSlider = uicontrol(hFig, 'Style', 'slider', ...
                                         'Min', -100, 'Max', 100, 'Value', 0, ...
                                         'Position', [160, 40, 640, 20]);

    % Store handles structure
    guidata(hFig, handles);

    % --- Nested Callback Functions ---

    function LoadButtonPushed(~, ~)
        handles = guidata(hFig);
        [file, path] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'}, 'Select Image');
        if isequal(file, 0)
            disp('User canceled selection');
            return;
        end

        fullPath = fullfile(path, file);
        try
            img = imread(fullPath);
            handles.OriginalImage = img;
            handles.CurrentImage = img;
            imshow(handles.OriginalAxes, handles.OriginalImage);
            imshow(handles.PreviewAxes, handles.CurrentImage);
            handles.BrightnessSlider.Value = 0;
            guidata(hFig, handles);
        catch ME
            msgbox(['Cannot load image: ' ME.message], 'Load Error', 'error');
        end
    end

    function SaveButtonPushed(~, ~)
        handles = guidata(hFig);
        if isempty(handles.CurrentImage)
            msgbox('No image to save.', 'Save Error', 'error');
            return;
        end

        [file, path] = uiputfile({'*.png', 'PNG Image'}, 'Save Image');
        if isequal(file, 0)
            disp('User canceled save');
            return;
        end

        fullPath = fullfile(path, file);
        imwrite(handles.CurrentImage, fullPath);
    end

    function ResetButtonPushed(~, ~)
        handles = guidata(hFig);
        if ~isempty(handles.OriginalImage)
            handles.CurrentImage = handles.OriginalImage;
            imshow(handles.PreviewAxes, handles.CurrentImage);
            handles.BrightnessSlider.Value = 0;
            guidata(hFig, handles);
        end
    end
end
