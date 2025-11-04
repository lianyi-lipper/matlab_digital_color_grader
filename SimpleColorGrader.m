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

% === 在这里添加第三阶段的控件 ===
% --- Sharpness Slider (Blur < 0 | Sharpen > 0) ---
uicontrol(hFig, 'Style', 'text', 'String', 'Sharpness', ...
'Position', [40, 95, 100, 22]);
handles.SharpnessSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', -1, 'Max', 1, 'Value', 0, ...
'Position', [160, 105, 200, 20]);

% --- Film Grain Slider ---
uicontrol(hFig, 'Style', 'text', 'String', 'Film Grain', ...
'Position', [400, 95, 100, 22]);
handles.GrainSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', 0, 'Max', 0.1, 'Value', 0, ... % 0 到 0.1 的方差
'Position', [500, 105, 200, 20]);

% --- HistEq Checkbox ---
handles.HistEqCheckbox = uicontrol(hFig, 'Style', 'checkbox', ...
'String', '一键增强 (HistEq)', ...
'Value', 0, ... % 0 = off, 1 = on
'Position', [720, 105, 100, 20]);
% === 第三阶段控件结束 ===


    % Store handles structure
    guidata(hFig, handles); % 保存一次 handles，确保滑块已创建

% --- 绑定监听器以实现实时预览 ---
% 告诉 MATLAB，只要这些滑块的值在变，就去调用 @UpdatePreview
addlistener(handles.BrightnessSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.ContrastSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.SaturationSlider, 'ContinuousValueChange', @UpdatePreview);

% === 在这里添加新监听器 ===
addlistener(handles.SharpnessSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.GrainSlider, 'ContinuousValueChange', @UpdatePreview);
% 复选框使用 'Callback' 属性，当它被点击时，也调用 UpdatePreview
set(handles.HistEqCheckbox, 'Callback', @UpdatePreview);
% === 新监听器结束 ===

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
            % === 添加重置代码 ===
            handles.SharpnessSlider.Value = 0;
            handles.GrainSlider.Value = 0;
            handles.HistEqCheckbox.Value = 0;
            % ====================
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
            % === 添加重置代码 ===
            handles.SharpnessSlider.Value = 0;
            handles.GrainSlider.Value = 0;
            handles.HistEqCheckbox.Value = 0;
            % ====================
            guidata(hFig, handles);
        end
    end

% --- 核心：统一更新函数 (版本 2) ---
function UpdatePreview(~, ~)
% 1. 获取最新的 handles
handles = guidata(hFig);
if isempty(handles.OriginalImage)
return;
end

% 2. 从“原图”开始处理
img = handles.OriginalImage;

% 3. 获取所有基础滑块的当前值
brightnessVal = handles.BrightnessSlider.Value;
contrastVal = handles.ContrastSlider.Value;
saturationVal = handles.SaturationSlider.Value;

% === 获取风格化控件的值 ===
sharpnessVal = handles.SharpnessSlider.Value;
grainVal = handles.GrainSlider.Value;
histEqVal = handles.HistEqCheckbox.Value; % (0 或 1)
% ==========================

% --- 4. 顺序应用效果 ---

% 效果 A: 亮度
img_processed = img + round(brightnessVal);

% 效果 B: 对比度
img_double = im2double(img_processed);
low_in = (1 - contrastVal) * 0.5;
high_in = 1 - low_in;
low_in = max(0, min(low_in, 0.999));
high_in = max(low_in + 0.001, min(high_in, 1));
img_adjusted = imadjust(img_double, [low_in, high_in], []);
img_processed = im2uint8(img_adjusted);

% 效果 C: 饱和度
hsvImg = rgb2hsv(img_processed);
hsvImg(:,:,2) = hsvImg(:,:,2) * saturationVal;
hsvImg(:,:,2) = min(hsvImg(:,:,2), 1.0);
img_processed = hsv2rgb(hsvImg);
img_processed = im2uint8(img_processed);

% === 效果 D: 锐化 / 模糊 ===
if sharpnessVal > 0 % 锐化
% 'Amount' 范围 0-2
img_processed = imsharpen(img_processed, 'Amount', sharpnessVal * 2);
elseif sharpnessVal < 0 % 模糊
% 'Sigma' 模糊半径
img_processed = imgaussfilt(img_processed, abs(sharpnessVal) * 3);
end
% (如果 sharpnessVal == 0, 则什么都不做)

% === 效果 E: 胶片颗粒 ===
if grainVal > 0
% 'gaussian' 模拟最常见的噪点，方差由 grainVal 控制
img_processed = imnoise(img_processed, 'gaussian', 0, grainVal);
end

% === 效果 F: 直方图均衡化 ===
if histEqVal == 1
% 检查图像是否为 RGB
if size(img_processed, 3) == 3
% 对彩色图像，转到 HSV，只对 V (明度) 通道进行均衡化
hsv_img = rgb2hsv(img_processed);
hsv_img(:,:,3) = histeq(hsv_img(:,:,3));
img_processed = hsv2rgb(hsv_img);
img_processed = im2uint8(img_processed);
else
% 对灰度图像，直接应用
img_processed = histeq(img_processed);
end
end

% --- 5. 更新 GUI ---
handles.CurrentImage = img_processed; % 保存处理后的图像
imshow(handles.CurrentImage, 'Parent', handles.PreviewAxes); % 显示
guidata(hFig, handles);
end
end
