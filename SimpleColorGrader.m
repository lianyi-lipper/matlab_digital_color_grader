classdef SimpleColorGrader < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        GridLayout    matlab.ui.container.GridLayout
        OriginalAxes  matlab.ui.control.UIAxes
        PreviewAxes   matlab.ui.control.UIAxes
        LoadButton    matlab.ui.control.Button
        SaveButton    matlab.ui.control.Button
        ResetButton   matlab.ui.control.Button
        BrightnessLabel matlab.ui.control.Label
        BrightnessSlider matlab.ui.control.Slider
    end

    % Properties that store data
    properties (Access = public)
        OriginalImage % Stores the original image data
        CurrentImage  % Stores the currently displayed (processed) image data
    end

    % App creation and deletion
    methods (Access = private)

        % Create UI components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 600];
            app.UIFigure.Name = 'Simple Digital Color Grader';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', 200};
            app.GridLayout.RowHeight = {'1x', 'fit', 'fit'};

            % Create OriginalAxes
            app.OriginalAxes = uiaxes(app.GridLayout);
            title(app.OriginalAxes, 'Original Image')
            app.OriginalAxes.Layout.Row = 1;
            app.OriginalAxes.Layout.Column = [1 2];

            % Create PreviewAxes
            app.PreviewAxes = uiaxes(app.GridLayout);
            title(app.PreviewAxes, 'Preview')
            app.PreviewAxes.Layout.Row = 1;
            app.PreviewAxes.Layout.Column = [3 4];

            % Create LoadButton
            app.LoadButton = uibutton(app.GridLayout, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Text = 'Load Image';
            app.LoadButton.Layout.Row = 2;
            app.LoadButton.Layout.Column = 1;

            % Create SaveButton
            app.SaveButton = uibutton(app.GridLayout, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Text = 'Save Image';
            app.SaveButton.Layout.Row = 2;
            app.SaveButton.Layout.Column = 2;

            % Create ResetButton
            app.ResetButton = uibutton(app.GridLayout, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Text = 'Reset';
            app.ResetButton.Layout.Row = 2;
            app.ResetButton.Layout.Column = 3;

            % Create BrightnessLabel
            app.BrightnessLabel = uilabel(app.GridLayout);
            app.BrightnessLabel.Text = 'Brightness';
            app.BrightnessLabel.Layout.Row = 3;
            app.BrightnessLabel.Layout.Column = 1;

            % Create BrightnessSlider
            app.BrightnessSlider = uislider(app.GridLayout);
            app.BrightnessSlider.Limits = [-100 100];
            app.BrightnessSlider.Value = 0;
            app.BrightnessSlider.Layout.Row = 3;
            app.BrightnessSlider.Layout.Column = [2 4];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)

        end

        % "Load Image" button pushed function
        function LoadButtonPushed(app, event)
            [file, path] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'}, 'Select Image');
            if isequal(file, 0)
                disp('User canceled selection');
            else
                fullPath = fullfile(path, file);
                try
                    % Read image
                    img = imread(fullPath);

                    % Store image in app properties
                    app.OriginalImage = img;
                    app.CurrentImage = img;

                    % Display image on both axes
                    imshow(app.OriginalAxes, app.OriginalImage);
                    imshow(app.PreviewAxes, app.CurrentImage);

                    % Reset slider
                    app.BrightnessSlider.Value = 0;

                catch ME
                    uialert(app, ['Cannot load image: ' ME.message], 'Load Error');
                end
            end
        end

        % "Save Image" button pushed function
        function SaveButtonPushed(app, event)
            if isempty(app.CurrentImage)
                uialert(app, 'No image to save.', 'Save Error');
                return;
            end
            [file, path] = uiputfile({'*.png', 'PNG Image'}, 'Save Image');
            if isequal(file, 0)
                disp('User canceled save');
            else
                fullPath = fullfile(path, file);
                imwrite(app.CurrentImage, fullPath);
            end
        end

        % "Reset" button pushed function
        function ResetButtonPushed(app, event)
            if ~isempty(app.OriginalImage)
                app.CurrentImage = app.OriginalImage;
                imshow(app.PreviewAxes, app.CurrentImage);
                app.BrightnessSlider.Value = 0;
            end
        end

    end


    % App Designer initialization
    methods (Access = public)

        % Construct app
        function app = SimpleColorGrader()

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
