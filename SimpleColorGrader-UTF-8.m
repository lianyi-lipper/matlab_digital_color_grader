function SimpleColorGrader()
    % 创建主窗口
    % 调整窗口大小为 1000x600 以容纳更清晰的布局
    hFig = figure('Name', 'Simple Color Grader', ...
        'Position', [100 100 1000 600], ...
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

    % === 布局区域划分 ===
    % 顶部：图像显示区 (占比约 65%)
    % 底部：控制面板区 (占比约 30%)
    
    % 1. 图像面板 (调整高度以腾出空间给控制台)
    hOriginalPanel = uipanel(hFig, 'Title', '原始图像', 'Position', [0.02 0.40 0.47 0.58]);
    hPreviewPanel = uipanel(hFig, 'Title', '预览结果', 'Position', [0.51 0.40 0.47 0.58]);

    % 创建坐标轴
    handles.OriginalAxes = axes('Parent', hOriginalPanel, 'Position', [0 0 1 1]);
    handles.PreviewAxes = axes('Parent', hPreviewPanel, 'Position', [0 0 1 1]);
    axis(handles.OriginalAxes, 'off');
    axis(handles.PreviewAxes, 'off');

    % 2. 控制面板 (使用 uipanel 统一管理 - 增加高度)
    hControlPanel = uipanel(hFig, 'Title', '调色控制台', 'Position', [0.02 0.02 0.96 0.36]);

    % --- 第一行：功能按钮 (Y=170) ---
    uicontrol(hControlPanel, 'Style', 'pushbutton', 'String', '加载图片', ...
        'Position', [40, 170, 100, 30], ...
        'Callback', @LoadButtonPushed);
    
    % 加载示例
    uicontrol(hControlPanel, 'Style', 'pushbutton', 'String', '加载示例', ...
        'Position', [150, 170, 100, 30], ...
        'Callback', @LoadExampleButtonPushed);

    uicontrol(hControlPanel, 'Style', 'pushbutton', 'String', '保存图片', ...
        'Position', [260, 170, 100, 30], ...
        'Callback', @SaveButtonPushed);
        
    handles.ResetButton = uicontrol(hControlPanel, 'Style', 'pushbutton', 'String', '重置所有', ...
        'Position', [370, 170, 100, 30], ...
        'Callback', @ResetButtonPushed);

    % --- 第二行：基础调整 (亮度、对比度、饱和度) (Y=120) ---
    % 亮度
    uicontrol(hControlPanel, 'Style', 'text', 'String', '亮度', ...
        'Position', [40, 120, 60, 20], 'HorizontalAlignment', 'right');
    handles.BrightnessSlider = uicontrol(hControlPanel, 'Style', 'slider', ...
        'Min', -100, 'Max', 100, 'Value', 0, ...
        'Position', [110, 120, 180, 20]);

    % 对比度
    uicontrol(hControlPanel, 'Style', 'text', 'String', '对比度', ...
        'Position', [350, 120, 60, 20], 'HorizontalAlignment', 'right');
    handles.ContrastSlider = uicontrol(hControlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 2, 'Value', 1, ...
        'Position', [420, 120, 180, 20]);

    % 饱和度
    uicontrol(hControlPanel, 'Style', 'text', 'String', '饱和度', ...
        'Position', [660, 120, 60, 20], 'HorizontalAlignment', 'right');
    handles.SaturationSlider = uicontrol(hControlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 2, 'Value', 1, ...
        'Position', [730, 120, 180, 20]);

    % --- 第三行：效果与增强 (锐度、颗粒、自动) (Y=70) ---
    % 锐度
    uicontrol(hControlPanel, 'Style', 'text', 'String', '锐度', ...
        'Position', [40, 70, 60, 20], 'HorizontalAlignment', 'right');
    handles.SharpnessSlider = uicontrol(hControlPanel, 'Style', 'slider', ...
        'Min', -1, 'Max', 1, 'Value', 0, ...
        'Position', [110, 70, 180, 20]);

    % 胶片颗粒
    uicontrol(hControlPanel, 'Style', 'text', 'String', '胶片颗粒', ...
        'Position', [350, 70, 60, 20], 'HorizontalAlignment', 'right');
    handles.GrainSlider = uicontrol(hControlPanel, 'Style', 'slider', ...
        'Min', 0, 'Max', 0.1, 'Value', 0, ...
        'Position', [420, 70, 180, 20]);

    % 一键增强
    handles.HistEqCheckbox = uicontrol(hControlPanel, 'Style', 'checkbox', ...
        'String', '一键增强 (直方图均衡)', ...
        'Value', 0, ...
        'Position', [730, 70, 200, 20]);

    % --- 第四行：高级分析 (边缘、分割、统计) (Y=20) ---
    uicontrol(hControlPanel, 'Style', 'text', 'String', '高级分析:', ...
        'Position', [40, 20, 60, 20], 'HorizontalAlignment', 'right', 'FontWeight', 'bold');
    
    % 边缘检测
    handles.EdgeCheckbox = uicontrol(hControlPanel, 'Style', 'checkbox', ...
        'String', '边缘检测 (Canny)', ...
        'Value', 0, ...
        'Position', [120, 20, 120, 20]);
        
    % 图像分割
    handles.SegCheckbox = uicontrol(hControlPanel, 'Style', 'checkbox', ...
        'String', '图像分割 (Otsu)', ...
        'Value', 0, ...
        'Position', [250, 20, 120, 20]);

    % 特征提取按钮
    uicontrol(hControlPanel, 'Style', 'pushbutton', 'String', '显示图像统计', ...
        'Position', [400, 15, 100, 30], ...
        'Callback', @ShowStatsButtonPushed);

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
    set(handles.EdgeCheckbox, 'Callback', @UpdatePreview);
    set(handles.SegCheckbox, 'Callback', @UpdatePreview);
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

        catch ME
            msgbox(['无法加载图片: ' ME.message], '加载错误', 'error');
        end
    end

    % 加载示例图片回调
    function LoadExampleButtonPushed(~, ~)
        handles = guidata(hFig);
        try
            % 加载 MATLAB 内置图像
            img = imread('peppers.png');
            handles.OriginalImage = img;

            % 处理缩略图
            preview_width = 800;
            img_height = size(img, 1);
            img_width = size(img, 2);
            preview_height = round(img_height * (preview_width / img_width));
            handles.ThumbnailImage = imresize(img, [preview_height, preview_width]);

            handles.CurrentImage = handles.ThumbnailImage;

            imshow(handles.OriginalImage, 'Parent', handles.OriginalAxes);
            
            % 重置滑块
            ResetControls(handles);
            
            guidata(hFig, handles);
            UpdatePreview();
        catch ME
            msgbox(['无法加载示例图片: ' ME.message], '错误', 'error');
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

    % 显示统计信息回调
    function ShowStatsButtonPushed(~, ~)
        handles = guidata(hFig);
        if isempty(handles.CurrentImage)
            msgbox('请先加载图片', '提示', 'warn');
            return;
        end
        
        % 获取当前处理后的图像 (使用缩略图或原图均可，这里用 CurrentImage 即预览图)
        img = handles.CurrentImage;
        
        % 创建新窗口显示统计
        hStatsFig = figure('Name', '图像特征统计', 'NumberTitle', 'off', 'Resize', 'on');
        
        % 1. 显示直方图
        subplot(2, 1, 1);
        if size(img, 3) == 3
            % 彩色图像：分别显示 R, G, B 直方图
            hold on;
            imhist(img(:,:,1)); 
            h = findobj(gca,'Type','patch'); set(h,'FaceColor','r','EdgeColor','r','FaceAlpha',0.5);
            imhist(img(:,:,2)); 
            h = findobj(gca,'Type','patch'); set(h,'FaceColor','g','EdgeColor','g','FaceAlpha',0.5);
            imhist(img(:,:,3)); 
            h = findobj(gca,'Type','patch'); set(h,'FaceColor','b','EdgeColor','b','FaceAlpha',0.5);
            hold off;
            title('RGB 直方图');
            legend('Red', 'Green', 'Blue');
        else
            imhist(img);
            title('灰度直方图');
        end
        
        % 2. 计算并显示统计数据
        subplot(2, 1, 2);
        axis off;
        
        img_double = im2double(img);
        mean_val = mean(img_double(:));
        std_val = std(img_double(:));
        
        statsText = {
            ['图像尺寸: ' num2str(size(img, 1)) ' x ' num2str(size(img, 2))];
            ['通道数: ' num2str(size(img, 3))];
            ' ';
            ['平均亮度 (Mean): ' num2str(mean_val, '%.4f')];
            ['标准差 (Std Dev): ' num2str(std_val, '%.4f')];
            ' ';
            '说明:';
            '平均亮度反映图像整体明暗。';
            '标准差反映图像对比度或细节丰富程度。';
        };
        
        text(0.1, 0.5, statsText, 'FontSize', 12, 'Interpreter', 'none');
    end

    % 辅助函数：重置控件
    function ResetControls(handles)
        handles.BrightnessSlider.Value = 0;
        handles.ContrastSlider.Value = 1;
        handles.SaturationSlider.Value = 1;
        handles.SharpnessSlider.Value = 0;
        handles.GrainSlider.Value = 0;
        handles.HistEqCheckbox.Value = 0;
        handles.EdgeCheckbox.Value = 0;
        handles.SegCheckbox.Value = 0;
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
        edgeVal = handles.EdgeCheckbox.Value;
        segVal = handles.SegCheckbox.Value;

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

        % 效果 G: 边缘检测 (互斥：如果开启，覆盖之前的颜色结果)
        if edgeVal == 1
            if size(img_processed, 3) == 3
                gray_img = rgb2gray(img_processed);
            else
                gray_img = img_processed;
            end
            edges = edge(gray_img, 'Canny');
            % 将二值边缘转为可视化的白色线条 (uint8 0-255)
            img_processed = uint8(edges) * 255;
        
        % 效果 H: 图像分割 (互斥：如果开启边缘检测则不显示分割，或者优先显示边缘)
        elseif segVal == 1
            if size(img_processed, 3) == 3
                gray_img = rgb2gray(img_processed);
            else
                gray_img = img_processed;
            end
            % Otsu 阈值分割
            level = graythresh(gray_img);
            bw = imbinarize(gray_img, level);
            img_processed = uint8(bw) * 255;
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

        % 2.关键优化：只处理“缩略图” 
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
            '【基础操作】'
            '1. 点击 [加载图片] 导入本地图片，或点击 [加载示例] 使用测试图。'
            '2. 点击 [保存图片] 将处理后的结果导出为文件。'
            '3. 点击 [重置所有] 恢复到原始状态。'
            ' '
            '【调色与特效】'
            '4. 拖动滑块调整亮度、对比度、饱和度、锐度及胶片颗粒。'
            '5. 勾选 [一键增强] 可自动进行直方图均衡化，改善光照。'
            ' '
            '【高级分析】'
            '6. 勾选 [边缘检测] (Canny算子) 或 [图像分割] (Otsu阈值) 查看图像结构。'
            '   (注意：开启分析模式时，调色效果将被覆盖)'
            '7. 点击 [显示图像统计] 查看RGB直方图、平均亮度及标准差数据。'
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