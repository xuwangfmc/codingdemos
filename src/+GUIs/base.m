classdef base < handle
%BASE Summary of this class goes here
%   Detailed explanation goes here

   properties
       hMainWindow
       hMainToolbar
       
       windowSize
       
       hExternalPanel
       hButtonHome
       hButtonBackUp
       hButtonNext
       hButtonAdvancedMode
       
       hInputImageSelectText
       hInputImageSelect
       
       inputMatrix
       imageStruct
       channelToShow
   end

   methods
        function obj = base(panelTitle)
            scrsz = get(0, 'ScreenSize');
            obj.windowSize = scrsz;
            obj.hMainWindow = figure('Position', [1 scrsz(4)/1 scrsz(3)*0.75 scrsz(3)*0.75], 'Color', [1 1 1]);
            
            % Hide Standard Toolbar
            set(obj.hMainWindow,'Toolbar','none');
            % Custom Toolbar
            obj.hMainToolbar = uitoolbar( obj.hMainWindow );
            icon = imresize(imread('+GUIs/images/icons/home_48.png','BackgroundColor',[1 1 1]), [16 16]);
            obj.hButtonHome = uipushtool(obj.hMainToolbar,'CData',icon,'TooltipString','Back to Home Screen.');
            icon = imresize(imread('+GUIs/images/icons/arrow_left_green_48.png','BackgroundColor',[1 1 1]), [16 16]);
            obj.hButtonBackUp = uipushtool(obj.hMainToolbar,'CData',icon,'TooltipString','Back to previous Screen.');
            icon = imresize(imread('+GUIs/images/icons/arrow_right_green_48.png','BackgroundColor',[1 1 1]), [16 16]);
            obj.hButtonNext = uipushtool(obj.hMainToolbar,'CData',icon,'TooltipString','To next Screen.');
            icon = imresize(imread('+GUIs/images/icons/add_48.png','BackgroundColor',[1 1 1]), [16 16]);
            obj.hButtonAdvancedMode = uitoggletool(obj.hMainToolbar,'CData',icon,'TooltipString','Toggle Advanced options...', ...
                                                    'Separator','on', ...
                                                    'ClickedCallback', @(source, event)(obj.changeScreenMode(source)));
            icon = imresize(imread('+GUIs/images/icons/search_48.png','BackgroundColor',[1 1 1]), [16 16]);
            uitoggletool(obj.hMainToolbar,'CData',icon,'TooltipString','Switch to and from zoom mode', ...
                                                    'Separator','on', ...
                                                    'ClickedCallback', @(source, event)(obj.changeZoomMode(source)));
            icon = imresize(imread('+GUIs/images/icons/mouse_48.png','BackgroundColor',[1 1 1]), [16 16]);
            uitoggletool(obj.hMainToolbar,'CData',icon,'TooltipString','Switch to and from pan mode', ...
                                                    'ClickedCallback', @(source, event)(obj.changePanMode(source)));   

            icon = imresize(imread('+GUIs/images/icons/refresh_48.png','BackgroundColor',[1 1 1]), [16 16]);
            uitoggletool(obj.hMainToolbar,'CData',icon,'TooltipString','Reset window', ...
                                                    'Separator','on', ...
                                                    'ClickedCallback', @(source, event)(obj.resetWindow(source)));            

            % external panel
            obj.hExternalPanel = uipanel('Title', panelTitle, ...
                                        'FontSize', 15,  ...
                                        'FontName', 'Courier', ...
                                        'BackgroundColor', 'white', ...
                                        'Units', 'Normalized', ...
                                        'Position', [.01 .01 .98 .98]);

        end
        
        function createInputImageSelectComboBoxAndText(obj, textPosition, position)
           % Input image select Combo box
           obj.hInputImageSelectText = uicontrol('Parent', obj.hExternalPanel, ...
                                        'Style', 'text', ...
                                        'String', 'Input Image:', ...
                                        'Units', 'Normalized', ...
                                        'HorizontalAlignment', 'left', ...
                                        'Position', textPosition, ...
                                        'Fontsize', 11, ...
                                        'FontName', 'Courier New',...
                                        'BackgroundColor', 'white');

           obj.hInputImageSelect = uicontrol('Style', 'popupmenu', ...
                                        'Parent', obj.hExternalPanel, ...
                                        'FontSize', 11, ...
                                        'FontName', 'Courier New',...
                                        'Units', 'Normalized', ...
                                        'Position', position,...
                                        'String', 'a|b|c',...
                                        'Callback', @(source, event)(obj.changeInput(source)));
           p = getpixelposition(obj.hInputImageSelect);
           setpixelposition(obj.hInputImageSelect, [p(1) p(2) 200 50]);
           
           set(obj.hInputImageSelect, 'String', obj.getExampleImagesFromExamplesDirectory('exampleImages'));
           
        end
        
        function ax = createAxesForImage(obj, position, parent)
            if ~exist('parent', 'var')
                parent = obj.hExternalPanel;
            end
            ax = axes('Parent', parent, ...
                                        'Box', 'on', ...
                                        'Visible', 'on', ...
                                        'XTick', [],...
                                        'YTick', [],...
                                        'Units', 'Normalized', ...
                                        'Position', position);

            % Draw initial image placeholder
            axis([0 1 0 1]);
            line([0 1], [1 0], 'LineWidth',1,'Color',[.8 .8 .8]);
            line([0 1], [0 1], 'LineWidth',1,'Color',[.8 .8 .8]);
        end
        
        function changeInput(obj, source)
           files = get(source, 'String');
           fileName = fullfile('exampleImages', files{get(source, 'Value')});
           imageRGB = imread(fileName);
           
            if isempty(imageRGB)
                throw(MException('GUIsBase:changeInputOnDisplay', 'The specified file could not be opened. It maybe corrupt or have been removed.'));
            end

            if isempty(obj.channelToShow)
                % Set a default
                obj.channelToShow = 'all';
            end
            
            obj.inputMatrix = rgb2ycbcr(imageRGB);
       end
        
        function changeZoomMode(obj, source)
            if strcmp(get(source, 'State'), 'on')
                % on
                zoom('on');
                set(source, 'CData', imresize(imread('+GUIs/images/icons/cross_48.png','BackgroundColor',[1 1 1]), [16 16]));
            else
                % off
                zoom('off');
                set(source, 'CData', imresize(imread('+GUIs/images/icons/search_48.png','BackgroundColor',[1 1 1]), [16 16]));
            end
        end
        
        function changePanMode(obj, source)
            if strcmp(get(source, 'State'), 'on')
                % on
                pan('on');
                set(source, 'CData', imresize(imread('+GUIs/images/icons/cross_48.png','BackgroundColor',[1 1 1]), [16 16]));
            else
                % off
                pan('off');
                set(source, 'CData', imresize(imread('+GUIs/images/icons/mouse_48.png','BackgroundColor',[1 1 1]), [16 16]));
            end
        end
       
        function changeScreenMode(obj, source)

            if strcmp(get(source, 'State'), 'on')
                % on
                % Override and add your code here
                set(source, 'CData', imresize(imread('+GUIs/images/icons/cancel_48.png','BackgroundColor',[1 1 1]), [16 16]));
            else
                % off
                % Override and add your code here
                set(source, 'CData', imresize(imread('+GUIs/images/icons/add_48.png','BackgroundColor',[1 1 1]), [16 16]));
            end
        end
        
        function fileNames = getExampleImagesFromExamplesDirectory(obj, directory)
           examples = struct2cell([dir(fullfile(directory, '*.bmp')) dir(fullfile(directory, '*.jpg')) dir(fullfile(directory, '*.png'))]);
           fileNames = examples(1,:);
       end
       
   end
end 