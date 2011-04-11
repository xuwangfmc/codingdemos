classdef TransformWindow < GUIs.base
%TRANSFORMWINDOW Summary of this class goes here
%   Detailed explanation goes here
   properties
       
       encoderInstance
       
       
   end
   
   methods
       function obj = TransformWindow(encoder, decoder)
           
           obj = obj@GUIs.base('Transform Coding: DCT');
           
           if ~exist('encoder', 'var')
               throw(MException('TransformWindow:TransformWindow', 'You must pass in the instance of the JPEG encoder.'));
           end
           
           obj.encoderInstance = encoder;
       end
   end

end
%{
   properties
       
       hMainWindow
       
       hExternalPanel
       hButtonBackUp
       hButtonNext
       
       hInputImageAxes
       hInputImage
       hOutputImage
       hOutputImageAxes
       hBasesPanel
       hButtonSetAll
       hButtonClearAll
       
       hSelectedBlockPanel
       hSelectedBlockAxes
       hSelectedBlock
       
       
       encoderInstance
       
       bases
       basisButtonImages
   end

   methods
       function obj = TransformWindow(encoder, decoder)
           
           if ~exist('encoder', 'var')
               throw(MException('TransformWindow:TransformWindow', 'You must pass in the instance of the JPEG encoder.'));
           end
           
           obj.encoderInstance = encoder;
           
           %obj.hMainWindow = openfig('+GUIs/demoDCT.fig');
           scrsz = get(0, 'ScreenSize');
           obj.hMainWindow = figure('Position', [1 scrsz(4)/1 scrsz(3)*0.6 scrsz(3)*0.6], 'Color', [1 1 1]);
            
           % external panel
           obj.hExternalPanel = uipanel('Title', 'Transform Coding: DCT', ...
                                        'FontSize', 15,  ...
                                        'FontName', 'Courier', ...
                                        'BackgroundColor', 'white', ...
                                        'Position', [.01 .01 .98 .98]);
                                    
           obj.hButtonBackUp = uicontrol('Style', 'pushbutton', ...
                                        'Parent', obj.hMainWindow, ...
                                        'FontSize', 8,  ...
                                        'String', 'Next Stage', ...
                                        'Position', [0.85 0.98 0.1 0.02], ...
                                        'Units', 'Normalized');
                                        
           obj.hButtonNext = uicontrol('Style', 'pushbutton', ...
                                        'Parent', obj.hMainWindow, ...
                                        'FontSize', 8,  ...    
                                        'String', 'Back Up', ...
                                        'Position', [0.75 0.98 0.1 0.02], ...
                                        'Units', 'Normalized');
           
           % Input and output image axes
           obj.hInputImageAxes = axes('Parent', obj.hExternalPanel, ...
                                        'Box', 'on', ...
                                        'Visible', 'off', ...
                                        'Position', [.05 .51 .45 .45], ...
                                        'Units', 'Normalized');

           obj.hInputImage = Subsampling.subsampledImageShow(obj.encoderInstance.imageStruct, obj.hInputImageAxes);           
           set(obj.hInputImage, 'ButtonDownFcn', @(src, evt)(obj.imageClick(src)));

           obj.hOutputImageAxes = axes('Parent', obj.hExternalPanel, ...
                                        'Box', 'on', ...
                                        'Visible', 'off', ...
                                        'Position', [.05 .05 .45 .45], ...
                                        'Units', 'Normalized');

           % TODO SET ******************************* 
           obj.hOutputImage = Subsampling.subsampledImageShow(obj.encoderInstance.imageStruct, obj.hOutputImageAxes);
           set(obj.hOutputImage, 'ButtonDownFcn', @(src, evt)(obj.imageClick(src)));

           % generate basis images
           % result is in column order
           [X,Y] = meshgrid(1:8,1:8);
           obj.bases = arrayfun(@(x,y)(TransformCoding.createBasisImage(x,y)), X(:), Y(:), 'UniformOutput', false);
           
           obj.hBasesPanel = uipanel('BackgroundColor', 'white', ...
                                    'Position', [0.55 0.55 0.3 0.3], ...
                                    'ResizeFcn', @(src, evt)(obj.resizeBasesPanel()));
           for i=1:length(obj.bases)
               % get basis button
               b = uicontrol('Parent', obj.hBasesPanel, ...
                                'Style', 'togglebutton', ...
                                ... %'String', ['basis' num2str(X(i)) num2str(Y(i))], ... % FOR DEBUGGING
                                'Units', 'Normalized', ...
                                'Position', [(0.125*(X(i)-1)) (1-(0.125*(Y(i)))) 0.125 0.125], ...
                                ... %Position', [(40*(X(i)-1)) (340-(40*(Y(i)))) 40 40], ...
                                'Tag', ['basis' num2str(i)], ... %['basis' num2str(X(i)) num2str(Y(i))], ...
                                'Value', 1, ...
                                'Callback', @(src, evt)(obj.toggleCoefficient(src)));
           end
           obj.hButtonSetAll = uicontrol('Style', 'pushbutton', ...
                                        'Parent', obj.hMainWindow, ...
                                        'FontSize', 8,  ...
                                        'String', 'Set All', ...
                                        'Callback', @(src, evt)(obj.setAllCoefficients()), ...
                                        'Position', [0.6 0.5 0.1 0.02], ...
                                        'Units', 'Normalized');

           obj.hButtonClearAll = uicontrol('Style', 'pushbutton', ...
                                        'Parent', obj.hMainWindow, ...
                                        'FontSize', 8,  ...    
                                        'String', 'Remove All', ...
                                        'Callback', @(src, evt)(obj.clearAllCoefficients()), ...
                                        'Position', [0.7 0.5 0.1 0.02], ...
                                        'Units', 'Normalized');
           
           obj.hSelectedBlockPanel = uipanel('BackgroundColor', 'white', ...
                                    'Title', 'Selected Block', ...
                                    'FontSize', 13,  ...
                                    'FontName', 'Courier', ...
                                    'Position', [0.5 0.05 0.4 0.4]);
           
           obj.hSelectedBlockAxes = axes('Parent', obj.hSelectedBlockPanel, ...
                                        'Box', 'on', ...
                                        'Visible', 'off', ...
                                        'Position', [.01 .55 .3 .5], ...
                                        'Units', 'Normalized');
           
       end

       function resizeBasesPanel(obj)
           
           % Force bases panel to be square
           p = getpixelposition(obj.hBasesPanel);
           %mp = min(p(3:4));
           setpixelposition(obj.hBasesPanel, [p(1) p(2) p(4) p(4)]);
           
           % update button cdata
           %[X,Y] = meshgrid(1:8,1:8);
           for i=1:length(obj.bases)
               % get basis button
               b = findobj(obj.hMainWindow, 'Tag', ['basis' num2str(i)]); %['basis' num2str(X(i)) num2str(Y(i))]);
               im = obj.bases{i};
               % normalise
               im = im - min(im(:));
               mx = max(im(:));
               if mx == 0
                    im = ones(size(im));
               else
                    im = im ./ mx;
               end
               % resize to button size
               xywh = getpixelposition(b);
               smallestDim = min(xywh(3:4));
               im = imresize(im, [smallestDim smallestDim], 'nearest');
               % create surrounding black box
               im(1:end, 1) = 0; im(1:end, end) = 0; im(1, 1:end) = 0; im(end, 1:end) = 0;
               
               obj.basisButtonImages{i} = repmat(im, [1 1 3]);
               % set on button
               %set(b, 'CData', obj.basisButtonImages{i});
               obj.toggleCoefficient(b);
           end
       end
       
       function imageClick(obj, imageHandle)
           % handle input / output image clicks
           if imageHandle == obj.hInputImage
               selectedPoint = get(obj.hInputImageAxes, 'CurrentPoint');
               bx = (floor((selectedPoint(1,1)-1) / 8)*8) + 1;
               by = (floor((selectedPoint(1,2)-1) / 8)*8) + 1;
               obj.hSelectedBlock = Subsampling.subsampledImageShow(obj.encoderInstance.imageStruct, 'Parent', obj.hSelectedBlockAxes, 'Channel', 'y', 'Block', [bx by 8 8]);
           else
               %disp(get(obj.hOutputImageAxes, 'CurrentPoint'))
           end
       end
       
       function toggleCoefficient(obj, hObject)
           if ~get(hObject, 'Value') 
               set(hObject, 'CData', []);
           else
               tag = get(hObject, 'Tag');
               set(hObject, 'CData', obj.basisButtonImages{str2double(tag(6:end))});
           end
       end
       
       function setAllCoefficients(obj)
           for i=1:length(obj.basisButtonImages)
               b = findobj(obj.hMainWindow, 'Tag', ['basis' num2str(i)]);
               set(b, 'Value', 1);
               obj.toggleCoefficient(b);
           end
       end
       
       function clearAllCoefficients(obj)
           for i=1:length(obj.basisButtonImages)
               b = findobj(obj.hMainWindow, 'Tag', ['basis' num2str(i)]);
               set(b, 'Value', 0);
               obj.toggleCoefficient(b);
           end
       end
   end
end 
%}