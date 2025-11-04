# matlab_digital_color_grader

**作品题目：** 《简易数字调色台 (Simple Digital Color Grader)》

#### 1\. 核心技术栈 

1.  **GUI 框架：** **App Designer**。
      * **理由：** 这是 MATLAB 目前主推的 GUI 开发环境。它比老的 GUIDE 界面更美观，控件更丰富，采用面向对象的编程方式，代码更易于管理。打开 MATLAB 命令行，输入 `appdesigner` 即可启动。
2.  **关键工具箱：** **Image Processing Toolbox**。
      * **理由：** 提供了所有需要的功能。在开始前，可以在命令行输入 `ver` 来检查你是否安装了这个工具箱。

#### 2\. 实现阶段 (分步走)

我建议你不要一开始就想把所有功能都做完，而是分阶段迭代：

##### 阶段一：搭建“骨架” (GUI 布局与文件I/O)

**目标：** 做出一个能“打开图片 -\> 显示图片 -\> 保存图片”的空壳子。

  * **GUI 布局 (App Designer):**
      * **`UIAxes` (坐标区):** 拖两个到界面上。一个命名为 `OriginalAxes` (用于显示原图)，一个命名为 `PreviewAxes` (用于显示处理后的图)。
      * **`Button` (按钮):** 拖三个按钮：“加载图像”、“保存图像”、“重置效果”。
      * **`Label` (标签):** 拖几个标签，用来放滑块的标题，比如“亮度”、“对比度”等。
      * **`Slider` (滑块):** 先拖一个“亮度”滑块。
  * **代码实现 (关键函数):**
      * **“加载图像”按钮的回调 (Callback):**
        ```matlab
        % 在 App Designer 中，这会自动生成一个函数
        function LoadButtonPushed(app, event)
            [file, path] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'}, '选择图像');
            if isequal(file, 0)
                disp('用户取消了选择');
            else
                fullPath = fullfile(path, file);
                try
                    % 1. 读取图像
                    img = imread(fullPath);
                    
                    % 2. 将图像存储在 App 的属性中，以便全局访问
                    app.OriginalImage = img; 
                    app.CurrentImage = img; % CurrentImage 用来存放处理后的版本
                    
                    % 3. 在两个坐标轴上显示
                    imshow(app.OriginalAxes, app.OriginalImage);
                    imshow(app.PreviewAxes, app.CurrentImage);
                catch ME
                    uialert(app, ['无法加载图像: ' ME.message], '加载错误');
                end
            end
        end
        ```
      * **“保存图像”按钮的回调:**
        ```matlab
        function SaveButtonPushed(app, event)
            if isempty(app.CurrentImage)
                uialert(app, '没有可保存的图像。', '保存错误');
                return;
            end
            [file, path] = uiputfile({'*.png', 'PNG Image'}, '保存图像');
            if isequal(file, 0)
                disp('用户取消了保存');
            else
                fullPath = fullfile(path, file);
                % 4. 写入图像
                imwrite(app.CurrentImage, fullPath);
            end
        end
        ```

##### 阶段二：实现“基础调色” (对应40分中的基础分)

**目标：** 让滑块动起来，能实时调整图像。

1.  **亮度 (Brightness):**

      * **原理：** 在 RGB 的三个通道上同时加上或减去一个偏移量。
      * **GUI：** 添加一个滑块 `BrightnessSlider`，范围设为 `[-100, 100]`，默认值 `0`。
      * **回调函数：** 使用 `ValueChangingFcn` (值变化中回调) 来实现**实时预览** (这是“交互性”的得分点)。
      * **关键函数：**
        ```matlab
        function BrightnessSliderValueChanging(app, event)
            value = event.Value; % 获取滑块的值
            % 归一化到 [0, 255] 范围，这里假设 value 是 -100 到 100
            brightnessOffset = round(value * 2.55); 
            
            % ！！注意：直接加减可能导致溢出 ( > 255 或 < 0 )
            % MATLAB 会自动处理uint8溢出（截断），所以可以直接加减
            processedImg = app.OriginalImage + brightnessOffset;
            
            app.CurrentImage = processedImg; % 更新当前图像
            imshow(app.PreviewAxes, app.CurrentImage); % 刷新显示
        end
        ```
      * **注意：** 这里的逻辑是每次都从 `app.OriginalImage` 开始调整。如果你从 `app.CurrentImage` 调整，效果会叠加，滑块一拖就废了。

2.  **对比度 (Contrast):**

      * **原理：** 简单的对比度调整是改变像素值与“中灰色”(128) 之间的距离。但我们有更简单的！
      * **关键函数：** `imadjust`。
      * **GUI：** 添加 `ContrastSlider`，范围 `[0, 2]`，默认值 `1`。
      * **回调：**
        ```matlab
        function ContrastSliderValueChanged(app, event) % 用 ValueChanged（释放后）可能更流畅
            value = event.Value; % 假设范围 0-2
            
            % 调整对比度。imadjust 需要一个 [low_in, high_in] 范围
            % 我们可以简单地通过滑块值来缩放这个范围
            low_in = (1 - value) * 0.5;
            high_in = 1 - low_in;
            
            % imadjust 对 [0, 1] 范围的 double 类型图像效果最好
            img_double = im2double(app.OriginalImage);
            processedImg = imadjust(img_double, [low_in, high_in], []);
            
            app.CurrentImage = im2uint8(processedImg); % 转回 uint8 存储和显示
            imshow(app.PreviewAxes, app.CurrentImage);
        end
        ```

3.  **饱和度 (Saturation):**

      * **原理：** 不能在 RGB 空间直接调。需要转换到 **HSV** (色相, 饱和度, 明度) 空间，调整 S 通道，再转回 RGB。
      * **关键函数：** `rgb2hsv` 和 `hsv2rgb`。
      * **GUI：** `SaturationSlider`，范围 `[0, 2]`，默认值 `1`。
      * **回调：**
        ```matlab
        function SaturationSliderValueChanged(app, event)
            value = event.Value; % 0=黑白, 1=原图, 2=高饱和
            
            % 1. 转到 HSV
            hsvImg = rgb2hsv(app.OriginalImage);
            
            % 2. 调整 S 通道
            % hsvImg(:,:,2) 就是饱和度通道
            hsvImg(:,:,2) = hsvImg(:,:,2) * value;
            
            % 3. 转回 RGB
            processedImg = hsv2rgb(hsvImg);
            
            app.CurrentImage = im2uint8(processedImg);
            imshow(app.PreviewAxes, app.CurrentImage);
        end
        ```

##### 阶段三：实现“风格化特效” (对应40分中的“难度”分)

这些可以做成“一键应用”的按钮。

1.  **“一键增强” (直方图均衡化):**

      * **关键函数：** `histeq`。
      * **GUI：** `HistEqButton` 按钮。
      * **回调：**
        ```matlab
        function HistEqButtonPushed(app, event)
            app.CurrentImage = histeq(app.CurrentImage); % 在当前图上处理
            imshow(app.PreviewAxes, app.CurrentImage);
        end
        ```

2.  **胶片颗粒 (Film Grain):**

      * **关键函数：** `imnoise`。
      * **GUI：** `GrainSlider` 滑块，范围 `[0, 0.1]`，默认 `0`。
      * **回调：**
        ```matlab
        function GrainSliderValueChanged(app, event)
            value = event.Value; % 噪声方差
            if value == 0
                processedImg = app.OriginalImage; % 假设从原图开始加
            else
                % 'gaussian' 模拟最常见的噪点
                processedImg = imnoise(app.OriginalImage, 'gaussian', 0, value);
            end
            app.CurrentImage = processedImg;
            imshow(app.PreviewAxes, app.CurrentImage);
        end
        ```

3.  **锐化 (Sharpen) / 模糊 (Blur):**

      * **关键函数：** `imsharpen` (锐化), `imgaussfilt` (高斯模糊)。
      * **GUI：** `SharpnessSlider`，范围 `[-1, 1]`。`> 0` 锐化，`< 0` 模糊。
      * **回调：**
        ```matlab
        function SharpnessSliderValueChanged(app, event)
            value = event.Value;
            if value > 0 % 锐化
                % 'Amount' 控制锐化量, 0-2
                processedImg = imsharpen(app.OriginalImage, 'Amount', value * 2);
            elseif value < 0 % 模糊
                % 'Sigma' 控制模糊半径
                processedImg = imgaussfilt(app.OriginalImage, 'Sigma', abs(value) * 3);
            else
                processedImg = app.OriginalImage;
            end
            app.CurrentImage = processedImg;
            imshow(app.PreviewAxes, app.CurrentImage);
        end
        ```

#### 3\. 性能优化 (对应15分“性能与效率”)

  * **问题：** 当你处理一张 4K 大图时，拖动滑块会**巨卡无比**。
  * **解决方案 (高级技巧):** **使用缩略图进行预览**。
    1.  **加载时：** 加载 `app.OriginalImage` 后，立刻创建一个缩略图：
        ```matlab
        % 比如限制预览图宽度为 800 像素
        app.ThumbnailImage = imresize(app.OriginalImage, [NaN, 800]); 
        ```
    2.  **滑块回调中：** 所有的计算（HSV转换、加噪点等）都**只对 `app.ThumbnailImage` 操作**。
        ```matlab
        % 示例：亮度滑块修改版
        function BrightnessSliderValueChanging(app, event)
            ...
            % 警告：这里假设你的所有操作都是基于原始缩略图
            % 你需要一个更复杂的“效果管线”来叠加效果，但基本思路如下：
            processedThumb = app.ThumbnailImage + brightnessOffset; 
            imshow(app.PreviewAxes, processedThumb); % 显示缩略图
            
            % 暂存最终处理后的大图，但不立即计算
            app.CurrentImage_FullRes_NeedsUpdate = true;
        end
        ```
    3.  **保存时：** 当用户点击“保存图像”时，检查 `app.CurrentImage_FullRes_NeedsUpdate` 标记。如果为 `true`，才在 `app.OriginalImage` (大图) 上**一次性**应用所有滑块的最终值，然后再保存。

#### 4\. 易用性与报告 (对应25分)

  * **“帮助”菜单 (15分):**
      * 在 App Designer 顶部添加“菜单栏”。
      * 添加“帮助” -\> “关于”菜单项。
      * **回调：** 弹出一个 `uialert`：
        ```matlab
        function AboutMenuSelected(app, event)
            msg = {'作品：简易数字调色台';
                   '课程：MATLAB实践基础';
                   '作者：[你的名字]';
                   '学号：[你的学号]'};
            uialert(app, msg, '关于');
        end
        ```
      * **错误提示：** 在 `imread` 等地方使用 `try-catch` 块（我已在上面示例中加入），并在 `catch` 中使用 `uialert` 提示用户，这就是“错误信息的清晰度”得分点。
  * **创作报告 (10分):**
      * **边做边截图！**
      * 图1：App Designer 的布局界面。
      * 图2：实现“加载/保存”功能的界面。
      * 图3：实现“HSV饱和度”调整的代码截图。
      * 图4：实现“锐化/模糊”的效果对比图。
      * 图5：最终的成品界面。

这个方案技术难度适中，MATLAB 函数支持良好，而且非常贴合你的专业背景。

这个详细的执行路径是否清晰？你想先从哪一步开始，或者对哪个函数的细节更感兴趣吗？(•\_•?)
