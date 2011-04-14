classdef Subsampling < GUIs.base
%SUBSAMPLINGWINDOW Summary of this class goes here
%   Detailed explanation goes here

   properties
       hChannelSelect
       hChannelSelectText
       hShowChannelInColours

       hInterpolationSelect
       hInterpolationSelectText

       hSubsampleModeSelect
       hShowChannelUpsampledCheckBox
       
       hInputImage
       hSubsampledImagePixelCount
       hSubsampledImageAxes
       hSubsampledImage
       hShownImage
       
       hSelectedBlockPanel
       hSubsamplingModeImageAxes

       lastClickedBlockX
       lastClickedBlockY
       
       defaultSubsamplingMode
       subsamplingMode
       interpolationMode
       showChannelInColour
       upsampleImage
   end

   methods
        function obj = Subsampling(fileName)
           
            obj = obj@GUIs.base('Subsampling: Utilising Perceptual Redundancy');
           
            % default modes
            obj.defaultSubsamplingMode = [1 3 6];
            obj.channelToShow = 'all';
            obj.interpolationMode = 'nearest';
            obj.upsampleImage = {true true true};
            obj.showChannelInColour = false;

            % Show input image selection
            obj.createInputImageSelectComboBoxAndText([0.06 0.96 0.25 0.03], [0.06 0.9 0.2 0.08]);

            % Popup: Channel Selection
            obj.hChannelSelectText = uicontrol('Parent', obj.hExternalPanel, ...
                                        'Style', 'text', ...
                                        'String', 'Channel type to show:', ...
                                        'Units', 'Normalized', ...
                                        'HorizontalAlignment', 'left', ...
                                        'Position', [0.35 0.96 0.22 0.03], ...
                                        'BackgroundColor', 'white',...
                                        'Fontsize', 11, ...
                                        'FontName', 'Courier New');

            obj.hChannelSelect = uicontrol('Style', 'popupmenu', ...
                                        'Parent', obj.hExternalPanel, ...
                                        'FontSize', 11, ...
                                        'FontName', 'Courier New',...
                                        'Units', 'Normalized', ...
                                        'Position',[0.4 0.92 0.25 0.03],...
                                        'String', 'All Channels/Whole Colour Image (Y+Cb+Cr Channels)|Luminance (Y Channel)|Chroma/Colour (Cb Channel)|Chroma/Colour (Cr Channel)',...
                                        'Callback', @(source, event)(obj.changeChannelOnDisplay(source)));

            obj.hShowChannelInColours = uicontrol('Style', 'checkbox', ...
                                        'Parent', obj.hExternalPanel, ...
                                        'FontSize', 9, ...
                                        'FontName', 'Courier New',...
                                        'Units', 'Normalized', ...
                                        'Position',[0.57 0.96 0.1 0.03],...
                                        'String', 'W. Colour?',...
                                        'Value', 0,...
                                        'Enable','off',...
                                        'Callback', @(source, event)(obj.changeShowChannelWithColour(source)));


            % Popup: Filter Selection
            obj.hInterpolationSelectText = uicontrol('Parent', obj.hExternalPanel, ...
                                        'Style', 'text', ...
                                        'String', 'Interpolation for upsample:', ...
                                        'Units', 'Normalized', ...
                                        'Position', [0.71 0.96 0.25 0.03], ...
                                        'HorizontalAlignment', 'left', ...
                                        'BackgroundColor', 'white',...
                                        'Fontsize', 10, ...
                                        'FontName', 'Courier New',...
                                        'Visible', 'off');

            obj.hInterpolationSelect = uicontrol('Style', 'popupmenu', ...
                                        'Parent', obj.hExternalPanel, ...
                                        'FontSize', 11, ...
                                        'FontName', 'Courier New',...
                                        'Units', 'Normalized', ...
                                        'Position',[0.71 0.92 0.25 0.03],...
                                        'String', {'Nearest neighbour' 'Bilinear' 'Bicubic'},...
                                        'Visible', 'off', ...
                                        'Callback', @(source, event)(obj.changeInterpolationMode(source)));
           
            % selected block panel
            obj.hSelectedBlockPanel = uipanel('Title', 'Subsampled chroma for selected block (click on image to select):', ...
                                        'Parent', obj.hExternalPanel, ...
                                        'FontSize', 10,  ...
                                        'FontName', 'Courier', ...
                                        'BackgroundColor', 'white', ...
                                        'Units', 'Normalized', ...
                                        'Visible', 'off', ...
                                        'Position', [.01 .01 .98 .25]);
           
            for i=1:3
                % Text elements showing pixel counts
                obj.hSubsampledImagePixelCount{i} = uicontrol('Parent', obj.hExternalPanel, ...
                                        'Style', 'text', ...
                                        'String', 'Number of Pixels: ', ...
                                        'Units', 'Normalized', ...
                                        'HorizontalAlignment', 'left', ...
                                        'Position', [((0.33*(i-1))+0.01) 0.85 0.32 0.03], ...
                                        'Fontsize', 11, ...
                                        'FontName', 'Courier New',...
                                        'BackgroundColor', [0.8 0.8 0.8]);

                obj.hSubsampledImageAxes{i} = obj.createAxesForImage([((0.33*(i-1))+.01) .35 .32 .5], obj.hExternalPanel);

                % Subsampling mode images
                uicontrol('Parent', obj.hExternalPanel, ...
                                        'Style', 'text', ...
                                        'String', 'Subsampling Mode:', ...
                                        'Units', 'Normalized', ...
                                        'HorizontalAlignment', 'left', ...
                                        'Position', [((0.33*(i-1))+0.01) 0.3 0.2 0.03], ...
                                        'Fontsize', 10, ...
                                        'FontName', 'Courier New',...
                                        'BackgroundColor', 'white');

                arrayfun(@(c, text)(uicontrol('Parent', obj.hSelectedBlockPanel, ...
                                        'Style', 'text', ...
                                        'String', text, ...
                                        'Units', 'Normalized', ...
                                        'HorizontalAlignment', 'left', ...
                                        'Position', [((0.34*(i-1))+(.01+(floor(c/3)*.15))) (.38+(rem(c+1,2)*.5)) .14 .1], ...
                                        'Fontsize', 11, ...
                                        'FontName', 'Courier New',...
                                        'BackgroundColor', 'white')), 1:4, { 'cb' 'block' 'cr' 'samples'},'UniformOutput', false);

                obj.hSubsamplingModeImageAxes{i} = arrayfun(@(c)(...
                                    obj.createAxesForImage([((0.34*(i-1))+(.01+(floor(c/3)*.15))) (.05+(rem(c+1,2)*.5)) .14 .31], obj.hSelectedBlockPanel) ...
                                    ), 1:4,'UniformOutput', false);

                obj.hSubsampleModeSelect{i} = uicontrol('Style', 'popupmenu', ...
                                        'Parent', obj.hExternalPanel, ...
                                        'FontSize', 10, ...
                                        'FontName', 'Courier New',...
                                        'Units', 'Normalized', ...
                                        'Position',[((0.33*(i-1))+0.01) 0.26 0.2 0.03],...
                                        'Value', obj.defaultSubsamplingMode(i), ...
                                        'String', obj.subsamplingModes(),...
                                        'Callback', @(source, event)(obj.changeSubsamplingModeForImage(source)));

                % update combos
                obj.changeSubsamplingModeForImage(obj.hSubsampleModeSelect{i});
               
                obj.hShowChannelUpsampledCheckBox{i} = uicontrol('Style', 'checkbox', ...
                                        'Parent', obj.hExternalPanel, ...
                                        'FontSize', 9, ...
                                        'FontName', 'Courier New',...
                                        'Units', 'Normalized', ...
                                        'Position',[((0.33*(i-1))+0.2) 0.26 0.15 0.03],...
                                        'String', 'Show upsampled?',...
                                        'Value', 1,...
                                        'Enable','off',...
                                        'Callback', @(source, event)(obj.toggleShowImageWithUpsampling(source)));
            end

            linkaxes(cell2mat(obj.hSubsampledImageAxes), 'xy');

            %obj.changeInput(obj.hInputImageSelect);

            if exist('fileName', 'var')
                % Load from file
                files = get(obj.hInputImageSelect, 'String');
                index = strmatch(fileName, files);
                set(obj.hInputImageSelect, 'Value', index);
            end

            % Give keyboard focus to image select element
            uicontrol(obj.hInputImageSelect);
        end

        function changeScreenMode(obj, source)
            if strcmp(get(source, 'State'), 'on')
                % on
                set(obj.hInterpolationSelect, 'Visible', 'on');
                set(obj.hInterpolationSelectText, 'Visible', 'on');
                set(obj.hSelectedBlockPanel, 'Visible', 'on');
                set(source, 'CData', imresize(imread('+GUIs/images/icons/cancel_48.png','BackgroundColor',[1 1 1]), [16 16]));
            else
                % off
                set(obj.hInterpolationSelect, 'Visible', 'off');
                set(obj.hInterpolationSelectText, 'Visible', 'off');
                set(obj.hSelectedBlockPanel, 'Visible', 'off');
                set(source, 'CData', imresize(imread('+GUIs/images/icons/add_48.png','BackgroundColor',[1 1 1]), [16 16]));
            end
        end
       
       function imageClick(obj, source)
           % handle input / output image clicks
            if ~isempty(obj.inputMatrix)
                
                % TODO: urg for loops

                for i=1:length(obj.hShownImage)
                    if source == obj.hShownImage{i}
                        selectedPoint = get(obj.hSubsampledImageAxes{i}, 'CurrentPoint');
                        obj.lastClickedBlockX = (floor((selectedPoint(1,1)-1) / 4)*4) + 1;
                        obj.lastClickedBlockY = (floor((selectedPoint(1,2)-1) / 2)*2) + 1;
                        break;
                    end
                end
                obj.updateSubsampleViews();
            end               
       end
       
       function updateSubsampleViews(obj)
            for i=1:length(obj.hShownImage)
                if ~isempty(obj.lastClickedBlockX) && ~isempty(obj.lastClickedBlockY)
                    %Subsampling.subsampledImageShow(obj.imageStruct{i}, 'Parent', obj.hSubsamplingModeImageAxes{i}{4}, ...
                    %                                'Channel', 'y', 'Block', [bx by 4 2], 'Interpolation', obj.interpolationMode);
                    imshow([1 1 1 1; 1 1 1 1], 'Parent', obj.hSubsamplingModeImageAxes{i}{4});
                    % Draw rectangles for mode
                    
                    % FIXME
                    
                    [ yHi yVi cbHi cbVi crHi crVi ] = Subsampling.modeToHorizontalAndVerticalSamplingFactors(obj.imageStruct{i}.mode);

                    mHi = max([yHi cbHi crHi]);
                    mVi = max([yVi cbVi crVi]);

                    X = [1:mHi:4];%((samplesPerHorizontalDistance - 1)*2)+1];
                    Y = [1:mVi:2];
                    %coordinatesOfRects = meshgrid(X, Y)
                    %if coordinatesOfRects == 1
                    %    coordinatesOfRects = [1 1];
                    %end
                    
                    % TODO: ARG!!!!!!!!!!!
                    coordinatesOfRects = [];
                    cnt = 1;
                    for l = 1:length(Y)
                        for k = 1:length(X)
                            coordinatesOfRects(cnt, :) = [X(k) Y(l)];
                            cnt = cnt + 1;
                        end
                    end

                    positionsLuminance = {[0.5 0.5 4 2]};

                    positionsChroma = arrayfun(@(x, y)([x-0.4 y-0.4 mHi-0.2 mVi-0.2]), coordinatesOfRects(:,1), coordinatesOfRects(:,2), 'UniformOutput', false);

                    cellfun(@(r)(rectangle('EdgeColor', [0 0 0], 'LineWidth', 0.5, 'Parent', obj.hSubsamplingModeImageAxes{i}{4}, 'Position', r)), ...
                                positionsLuminance);
                    cellfun(@(r)(rectangle('EdgeColor', [0 0 0.7], 'LineWidth', 0.5, 'Parent', obj.hSubsamplingModeImageAxes{i}{4}, 'Position', r)), ...
                                positionsChroma);
                    cellfun(@(r)(rectangle('EdgeColor', [0 0.7 0], 'LineWidth', 0.5, 'Parent', obj.hSubsamplingModeImageAxes{i}{4}, 'Position', r)), ...
                                cellfun(@(arr)([arr(1)+0.1 arr(2)+0.1 arr(3)-0.2 arr(4)-0.2]), positionsChroma,'UniformOutput', false));


                    Subsampling.subsampledImageShow(obj.imageStruct{i}, 'Parent', obj.hSubsamplingModeImageAxes{i}{1}, ...
                                                    'Channel', 'cb',  'Block', [obj.lastClickedBlockX obj.lastClickedBlockY 4 2], ...
                                                    'Interpolation', obj.interpolationMode, 'ColourDisplay', obj.showChannelInColour);
                    Subsampling.subsampledImageShow(obj.imageStruct{i}, 'Parent', obj.hSubsamplingModeImageAxes{i}{3}, ...
                                                    'Channel', 'cr', 'Block', [obj.lastClickedBlockX obj.lastClickedBlockY 4 2], ...
                                                    'Interpolation', obj.interpolationMode, 'ColourDisplay', obj.showChannelInColour);
                    Subsampling.subsampledImageShow(obj.imageStruct{i}, 'Parent', obj.hSubsamplingModeImageAxes{i}{2}, ...
                                                    'Channel', 'all', 'Block', [obj.lastClickedBlockX obj.lastClickedBlockY 4 2], ...
                                                    'Interpolation', obj.interpolationMode, 'ColourDisplay', obj.showChannelInColour);
                end
            end
       end
       
       function modes = subsamplingModes(obj)
           modes = {'4:4:4' '4:4:0' '4:2:2' '4:2:0' '4:1:1' '4:1:0'};
       end
       
       function changeSubsamplingModeForImage(obj, source)
           for i=1:length(obj.hSubsampleModeSelect)
               if source == obj.hSubsampleModeSelect{i}
                    strings = get(source, 'String');
                    obj.subsamplingMode{i} = strings{get(source, 'Value')};
                    break;
               end
           end

           obj.doSubsamplingOnImageMatrix();
           obj.updateAxes();
       end
       
        function changeInput(obj, source)
            % Call super class implementation which does the loading etc
            obj.changeInput@GUIs.base(source);
            
            obj.doSubsamplingOnImageMatrix();
            obj.updateAxes();
        end
       
       function changeChannelOnDisplay(obj, source)
            selected = get(source, 'Value');
            switch(selected)
                case 1
                    obj.channelToShow = 'all';
                case 2
                    obj.channelToShow = 'y';
                case 3
                    obj.channelToShow = 'cb';
                case 4
                    obj.channelToShow = 'cr';
            end
            
            obj.updateCheckBoxStatus();
            
            obj.updateAxes();
       end
       
        function changeShowChannelWithColour(obj, source)
            obj.showChannelInColour = get(source, 'Value');
            obj.updateAxes();
        end
       
        function toggleShowImageWithUpsampling(obj, source)
            for i=1:length(obj.hShowChannelUpsampledCheckBox)
                if source == obj.hShowChannelUpsampledCheckBox{i}
                    if get(obj.hShowChannelUpsampledCheckBox{i}, 'Value')

                        obj.upsampleImage{i} = true;

                        %get(obj.hSubsampledImageAxes{i}, 'XLim')
                        %get(obj.hSubsampledImageAxes{i}, 'YLim')
                        %set(obj.hSubsampledImageAxes{i}, 'XLimMode', 'auto');

                        obj.updateAxes();
                    else

                        obj.upsampleImage{i} = false;
                        obj.updateAxes();
                        % update the settings for the axis
                        %get(obj.hSubsampledImageAxes{i}, 'XLim')
                        if ~isempty(obj.inputMatrix)
                            set(obj.hSubsampledImageAxes{i}, 'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [1 size(obj.inputMatrix, 2)], 'YLim', [1 size(obj.inputMatrix, 1)]);
                            axis(obj.hSubsampledImageAxes{i}, 'image');
                        end
                    end
                    break;
                end
            end
        end
       
        function updateCheckBoxStatus(obj)
            if strcmp(obj.channelToShow, 'all')
                % disable
                enabled = 'off';
            else
                % enable
                enabled = 'on';
            end

            set(obj.hShowChannelInColours, 'Enable', enabled);

            for i=1:length(obj.hShowChannelUpsampledCheckBox)
                set(obj.hShowChannelUpsampledCheckBox{i}, 'Enable', enabled);
            end
        end
       
        function changeInterpolationMode(obj, source)
            switch get(source, 'Value')
                case 1
                    obj.interpolationMode = 'nearest';
                case 2
                    obj.interpolationMode = 'bilinear';
                case 3
                    obj.interpolationMode = 'bicubic';
            end
           
            obj.updateAxes();
        end
       
       function doSubsamplingOnImageMatrix(obj)
            if ~isempty(obj.inputMatrix)
                for i=1:length(obj.subsamplingMode)
                    obj.imageStruct{i} = Subsampling.ycbcrImageToSubsampled(obj.inputMatrix, 'Mode', obj.subsamplingMode{i});
                end
            end
       end

       function updatePixelCounts(obj)
           for i=1:length(obj.imageStruct)
               [ yHi yVi cbHi cbVi crHi crVi ] = Subsampling.modeToHorizontalAndVerticalSamplingFactors(obj.imageStruct{i}.mode);
               pixelcount = numel(obj.imageStruct{i}.y) + numel(obj.imageStruct{i}.cb) + numel(obj.imageStruct{i}.cr);
               set(obj.hSubsampledImagePixelCount{i}, 'String', ['Number of Pixels: ' num2str(pixelcount)]);
           end
       end

       function updateAxes(obj)
           if ~isempty(obj.inputMatrix)
               for i=1:length(obj.imageStruct)
                    if obj.upsampleImage{i}
                        obj.hShownImage{i} = Subsampling.subsampledImageShow(obj.imageStruct{i}, 'Parent', obj.hSubsampledImageAxes{i}, ...
                            'Channel', obj.channelToShow, 'Interpolation', obj.interpolationMode, 'ColourDisplay', obj.showChannelInColour);
                    else
                        obj.hShownImage{i} = Subsampling.subsampledImageShow(obj.imageStruct{i}, 'Parent', obj.hSubsampledImageAxes{i}, ...
                            'Channel', obj.channelToShow, 'ColourDisplay', obj.showChannelInColour, 'Upsample', false);
                    end
                    set(obj.hShownImage{i}, 'ButtonDownFcn', @(source, evt)(obj.imageClick(source)));
               end
               obj.updatePixelCounts();
               obj.updateSubsampleViews();
           end
       end
   end
end 