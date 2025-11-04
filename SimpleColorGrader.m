function SimpleColorGrader()
% 创建主窗口
hFig = figure('Name', '简易数字调色台', ...
'Position', [100 100 820 500], ...
'NumberTitle', 'off', ...
'MenuBar', 'figure', ...
'Resize', 'off');

% === 在这里添加菜单栏代码 ===
hMenuHelp = uimenu(hFig, 'Label', '帮助');
uimenu(hMenuHelp, 'Label', '使用说明', 'Callback', @ShowHelpCallback);
uimenu(hMenuHelp, 'Label', '关于', 'Callback', @ShowAboutCallback);
% === 菜单栏代码结束 ===

% 创建用于存储句柄和图像的数据结构
handles.OriginalImage = [];
handles.CurrentImage = [];

% 创建界面面板
hOriginalPanel = uipanel(hFig, 'Title', '原始图像', 'Position', [0.025 0.24 0.46 0.72]);
hPreviewPanel = uipanel(hFig, 'Title', '预览', 'Position', [0.515 0.24 0.46 0.72]);

% 创建坐标轴
handles.OriginalAxes = axes('Parent', hOriginalPanel, 'Position', [0 0 1 1]);
handles.PreviewAxes = axes('Parent', hPreviewPanel, 'Position', [0 0 1 1]);
axis(handles.OriginalAxes, 'off');
axis(handles.PreviewAxes, 'off');

% 创建按钮
uicontrol(hFig, 'Style', 'pushbutton', 'String', '加载图片', ...
'Position', [40, 70, 100, 22], ...
'Callback', @LoadButtonPushed);
uicontrol(hFig, 'Style', 'pushbutton', 'String', '保存图片', ...
'Position', [160, 70, 100, 22], ...
'Callback', @SaveButtonPushed);
handles.ResetButton = uicontrol(hFig, 'Style', 'pushbutton', 'String', '重置', ...
'Position', [280, 70, 100, 22], ...
'Callback', @ResetButtonPushed);

% 创建滑块和标签
uicontrol(hFig, 'Style', 'text', 'String', '亮度', ...
'Position', [40, 30, 100, 22]);
handles.BrightnessSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', -100, 'Max', 100, 'Value', 0, ...
'Position', [160, 40, 640, 20]);

% --- 对比度滑块 ---
uicontrol(hFig, 'Style', 'text', 'String', '对比度', ...
'Position', [40, 5, 100, 22]);
handles.ContrastSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', 0, 'Max', 2, 'Value', 1, ... % 0=最低, 1=不变, 2=最高
'Position', [160, 15, 200, 20]); % 调整了位置

% --- 饱和度滑块 ---
uicontrol(hFig, 'Style', 'text', 'String', '饱和度', ...
'Position', [400, 5, 100, 22]); % 调整了位置
handles.SaturationSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', 0, 'Max', 2, 'Value', 1, ... % 0=黑白, 1=不变, 2=高饱和
'Position', [500, 15, 300, 20]); % 调整了位置

% --- 锐度滑块 (小于0模糊 | 大于0锐化) ---
uicontrol(hFig, 'Style', 'text', 'String', '锐度', ...
'Position', [40, 95, 100, 22]);
handles.SharpnessSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', -1, 'Max', 1, 'Value', 0, ...
'Position', [160, 105, 200, 20]);

% --- 胶片颗粒滑块 ---
uicontrol(hFig, 'Style', 'text', 'String', '胶片颗粒', ...
'Position', [400, 95, 100, 22]);
handles.GrainSlider = uicontrol(hFig, 'Style', 'slider', ...
'Min', 0, 'Max', 0.1, 'Value', 0, ... % 0 到 0.1 的方差
'Position', [500, 105, 200, 20]);

% --- 直方图均衡化复选框 ---
handles.HistEqCheckbox = uicontrol(hFig, 'Style', 'checkbox', ...
'String', '一键增强 (直方图均衡)', ...
'Value', 0, ... % 0 = 关闭, 1 = 开启
'Position', [720, 105, 100, 20]);


% 存储 handles 结构
guidata(hFig, handles); % 保存一次 handles，确保滑块已创建

% --- 绑定监听器以实现实时预览 ---
% 告诉 MATLAB，只要这些滑块的值在变，就去调用 @UpdatePreview
addlistener(handles.BrightnessSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.ContrastSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.SaturationSlider, 'ContinuousValueChange', @UpdatePreview);

addlistener(handles.SharpnessSlider, 'ContinuousValueChange', @UpdatePreview);
addlistener(handles.GrainSlider, 'ContinuousValueChange', @UpdatePreview);
% 复选框使用 'Callback' 属性，当它被点击时，也调用 UpdatePreview
set(handles.HistEqCheckbox, 'Callback', @UpdatePreview);

% --- 嵌套回调函数 ---

function LoadButtonPushed(~, ~)
handles = guidata(hFig);
[file, path] = uigetfile({'*.jpg;*.png;*.bmp', '图片文件'}, '选择图片');
if isequal(file, 0)
disp('用户取消了选择');
return;
end

fullPath = fullfile(path, file);
try
img = imread(fullPath);
handles.OriginalImage = img;

% === 性能优化：创建并存储缩略图 ===
% 将图像缩放到固定宽度800像素，保持高宽比
preview_width = 800;
img_height = size(img, 1);
img_width = size(img, 2);
preview_height = round(img_height * (preview_width / img_width));

handles.ThumbnailImage = imresize(img, [preview_height, preview_width]);
% ===================================

handles.CurrentImage = handles.ThumbnailImage; % 初始预览也用缩略图

imshow(handles.OriginalImage, 'Parent', handles.OriginalAxes);
% imshow(handles.CurrentImage, 'Parent', handles.PreviewAxes); % <--- 下一行会覆盖它

% 重置所有滑块
handles.BrightnessSlider.Value = 0;
handles.ContrastSlider.Value = 1;
handles.SaturationSlider.Value = 1;
handles.SharpnessSlider.Value = 0;
handles.GrainSlider.Value = 0;
handles.HistEqCheckbox.Value = 0;

guidata(hFig, handles);

% !! 加载后，手动调用一次 UpdatePreview 来显示正确的缩略图 !!
UpdatePreview(); % 确保预览区显示的是处理后的缩略图

catch ME
msgbox(['无法加载图片: ' ME.message], '加载错误', 'error');
end
end

function SaveButtonPushed(~, ~)
handles = guidata(hFig);
if isempty(handles.OriginalImage) % <-- 改为检查 OriginalImage
msgbox('没有可保存的图片。', '保存错误', 'error');
return;
end

[file, path] = uiputfile({'*.png', 'PNG Image'}, '保存图片');
if isequal(file, 0)
disp('用户取消了保存');
return;
end

fullPath = fullfile(path, file);

% === 性能优化：保存时处理全分辨率图像 ===
% 1. 提示用户正在处理
set(hFig, 'Pointer', 'watch'); % 鼠标变“忙碌”
drawnow; % 立即刷新界面

try
% 2. 对“原图”调用处理管线
img_to_save = ProcessImage(handles.OriginalImage, handles);

% 3. 写入全分辨率的处理结果
imwrite(img_to_save, fullPath);

catch ME
msgbox(['保存失败: ' ME.message], '保存错误', 'error');
end

% 4. 恢复鼠标
set(hFig, 'Pointer', 'arrow');
% ========================================
end

function ResetButtonPushed(~, ~)
handles = guidata(hFig);
if ~isempty(handles.OriginalImage)
% 恢复为未处理的缩略图
handles.CurrentImage = handles.ThumbnailImage; % <--- 修改点
imshow(handles.CurrentImage, 'Parent', handles.PreviewAxes);

% 重置所有滑块
handles.BrightnessSlider.Value = 0;
handles.ContrastSlider.Value = 1;
handles.SaturationSlider.Value = 1;
handles.SharpnessSlider.Value = 0;
handles.GrainSlider.Value = 0;
handles.HistEqCheckbox.Value = 0;

guidata(hFig, handles);
end
end

% --- 核心处理管线 (新函数) ---
function outputImg = ProcessImage(inputImg, handles)
% 1. 获取所有控件的值
brightnessVal = handles.BrightnessSlider.Value;
contrastVal = handles.ContrastSlider.Value;
saturationVal = handles.SaturationSlider.Value;
sharpnessVal = handles.SharpnessSlider.Value;
grainVal = handles.GrainSlider.Value;
histEqVal = handles.HistEqCheckbox.Value;

% 2. 从“输入图像”开始处理
img_processed = inputImg;

% --- 3. 顺序应用效果 ---

% 效果 A: 亮度
img_processed = img_processed + round(brightnessVal);

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

% 效果 D: 锐化 / 模糊
if sharpnessVal > 0
img_processed = imsharpen(img_processed, 'Amount', sharpnessVal * 2);
elseif sharpnessVal < 0
img_processed = imgaussfilt(img_processed, abs(sharpnessVal) * 3);
end

% 效果 E: 胶片颗粒
if grainVal > 0
img_processed = imnoise(img_processed, 'gaussian', 0, grainVal);
end

% 效果 F: 直方图均衡化
if histEqVal == 1
if size(img_processed, 3) == 3
hsv_img = rgb2hsv(img_processed);
hsv_img(:,:,3) = histeq(hsv_img(:,:,3));
img_processed = hsv2rgb(hsv_img);
img_processed = im2uint8(img_processed);
else
img_processed = histeq(img_processed);
end
end

% 4. 返回处理结果
outputImg = img_processed;
end

% --- 核心：统一更新函数 (版本 3 - 优化版) ---
function UpdatePreview(~, ~)
% 1. 获取最新的 handles
handles = guidata(hFig);
if isempty(handles.OriginalImage)
return;
end

% 2. !! 关键优化：只处理“缩略图” !!
img_to_process = handles.ThumbnailImage; % 使用缩略图进行处理

% 3. 调用核心管线
img_processed = ProcessImage(img_to_process, handles);

% 4. 更新 GUI
handles.CurrentImage = img_processed; % CurrentImage 现在存的是“处理后的缩略图”
imshow(handles.CurrentImage, 'Parent', handles.PreviewAxes); % 显示
guidata(hFig, handles);
end

% --- 菜单栏回调函数 ---

function ShowHelpCallback(~, ~)
title = '使用说明';
msg = {
'1. 点击 [加载图片] 加载一张图片。'
'2. 拖动下方的滑块，实时预览调色效果。'
'3. 勾选 [一键增强] 可自动优化对比度。'
'4. 点击 [保存图片] 保存处理后的图片。'
'5. 点击 [重置] 恢复到原始图像和默认设置。'
};
msgbox(msg, title, 'help');
end

function ShowAboutCallback(~, ~)
title = '关于';
msg = {
'作品: 简易数字调色台 (v1.0)'
'课程: MATLAB实践基础'
'作者: [填写你的名字]'
'学号: [填写你的学号]'
};
msgbox(msg, title, 'modal');
end

end