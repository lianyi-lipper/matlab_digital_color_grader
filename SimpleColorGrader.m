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

% === 在这里添加新代码 ===
% --- Contrast Slider ---
uicontrol(hFig, 'Style', 'text', 'String', 'Contrast', ...
'Position', [40, 5, 100, 22]);
handles.ContrastSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', 0, 'Max', 2, 'Value', 1, ... % 0=最低, 1=不变, 2=最高
'Position', [160, 15, 200, 20]); % 调整了位置

% --- Saturation Slider ---
uicontrol(hFig, 'Style', 'text', 'String', 'Saturation', ...
'Position', [400, 5, 100, 22]); % 调整了位置
handles.SaturationSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', 0, 'Max', 2, 'Value', 1, ... % 0=黑白, 1=不变, 2=高饱和
'Position', [500, 15, 300, 20]); % 调整了位置
% === 新代码结束 ===

    % Store handles structure
    guidata(hFig, handles); % 保存一次 handles，确保滑块已创建

% --- 绑定监听器以实现实时预览 ---
% 告诉 MATLAB，只要这些滑块的值在变，就去调用 @UpdatePreview
addlistener(handles.BrightnessSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.ContrastSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.SaturationSlider, 'ContinuousValueChange', @UpdatePreview);

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
            imshow(handles.OriginalImage, 'Parent', handles.OriginalAxes);
            imshow(handles.CurrentImage, 'Parent', handles.PreviewAxes);
            % 重置所有滑块
            handles.BrightnessSlider.Value = 0;
            handles.ContrastSlider.Value = 1;
            handles.SaturationSlider.Value = 1;
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
            imshow(handles.CurrentImage, 'Parent', handles.PreviewAxes);
            % 重置所有滑块
            handles.BrightnessSlider.Value = 0;
            handles.ContrastSlider.Value = 1;
            handles.SaturationSlider.Value = 1;
            guidata(hFig, handles);
        end
    end

% --- 核心：统一更新函数 ---
function UpdatePreview(~, ~)
% 1. 获取最新的 handles
handles = guidata(hFig);
if isempty(handles.OriginalImage)
return; % 如果没有图像，则不执行任何操作
end

% 2. 从“原图”开始处理（！！）
img = handles.OriginalImage;

% 3. 获取所有滑块的当前值
brightnessVal = handles.BrightnessSlider.Value;
contrastVal = handles.ContrastSlider.Value;
saturationVal = handles.SaturationSlider.Value;

% --- 4. 顺序应用效果 ---

% 效果 A: 亮度
% MATLAB 的 uint8 图像会自动处理饱和运算（<0 变 0, >255 变 255）
img_processed = img + round(brightnessVal);

% 效果 B: 对比度 (基于上一步的结果)
% imadjust 需要 [0, 1] 范围的 double 图像
img_double = im2double(img_processed);

low_in = (1 - contrastVal) * 0.5;
high_in = 1 - low_in;
% 确保范围在 [0, 1] 内且 low < high
low_in = max(0, min(low_in, 0.999));
high_in = max(low_in + 0.001, min(high_in, 1));

img_adjusted = imadjust(img_double, [low_in, high_in], []);
img_processed = im2uint8(img_adjusted); % 转回 uint8

% 效果 C: 饱和度 (基于上一步的结果)
hsvImg = rgb2hsv(img_processed);
% 调整 S (Saturation) 通道
hsvImg(:,:,2) = hsvImg(:,:,2) * saturationVal;
% 裁剪 S 通道，防止值超过 1.0
hsvImg(:,:,2) = min(hsvImg(:,:,2), 1.0);

img_processed = hsv2rgb(hsvImg); % 转回 RGB
img_processed = im2uint8(img_processed); % 转回 uint8

% --- 5. 更新 GUI ---
handles.CurrentImage = img_processed; % 保存处理后的图像
imshow(handles.CurrentImage, 'Parent', handles.PreviewAxes); % 显示

% !! 注意：这里不需要 guidata(hFig, handles) !!
% 因为我们只是在读取 handles，并且 UpdatePreview 不会改变滑块的值
% 我们只在 Load, Reset, Save 这些改变 App 状态的函数里用 guidata
% *更正：需要保存 CurrentImage，所以还是加上 guidata*
guidata(hFig, handles);
end
end
