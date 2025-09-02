function MicroBREW(imageName, numFrames, save_result)
    [~, baseName, ~] = fileparts(imageName); 

    % Directory for saving ROI-outlined frames
    roiDir = fullfile(pwd, strcat(baseName, '_roiFrames'));
    if ~exist(roiDir, 'dir'), mkdir(roiDir); end

    video = VideoReader(imageName);  % Video file

    for frame_id = 1:numFrames
        v1 = read(video, frame_id); % Read each frame
        v1_adj = edge(v1); % Perform edge detection
        v1_adj1 = im2double(v1_adj); 
        v1_adj2 = imdilate(v1_adj1, strel('disk', 10)); 
        v1_adj3 = imfill(v1_adj2); 
        objects_v2 = xor(bwareaopen(v1_adj3, 8000), bwareaopen(v1_adj3, 13000)); 
        [objects_v2, nobjs2] = bwlabel(objects_v2);
        obj_props = regionprops(objects_v2); 
        
        if nobjs2 < 2
            disp('Less than 2 traps detected, skipping frame.');
            continue;
        end

        % Create figure for ROI-outlined frame
        fig = figure('Visible', 'off'); % Prevent figure from displaying
        imshow(v1, []); hold on; % Display the original frame
        
        % Add outlines for ROIs
        for trap_id = 1:nobjs2
            tid = trap_id;

            % ROI 1: Polygon near centroid
            vertices1 = [obj_props(tid).Centroid(1)-14 obj_props(tid).Centroid(2)+16;
                         obj_props(tid).Centroid(1)-28 obj_props(tid).Centroid(2)+35;
                         obj_props(tid).Centroid(1)-28 obj_props(tid).Centroid(2)+106;
                         obj_props(tid).Centroid(1)+30 obj_props(tid).Centroid(2)+106; 
                         obj_props(tid).Centroid(1)+30 obj_props(tid).Centroid(2)+35;
                         obj_props(tid).Centroid(1)+15 obj_props(tid).Centroid(2)+16];
            plot(vertices1(:, 1), vertices1(:, 2), 'r-', 'LineWidth', 1); % Red outline

            % ROI 2: Capsule-shaped region above centroid
            centerX = obj_props(tid).Centroid(1);
            centerY = obj_props(tid).Centroid(2) - 15;  % Move up/down adjustment
            radius = 30; numPoints = 50; heightExtension = 20;

            theta = linspace(0, pi, numPoints);  % Half-circle
            x_half_circle = centerX + radius * cos(theta);
            y_half_circle = centerY + radius * sin(theta);

            % Extend height
            x_left = repmat(x_half_circle(1), heightExtension, 1);
            y_left = linspace(y_half_circle(1), y_half_circle(1) - heightExtension, heightExtension)';
            x_right = repmat(x_half_circle(end), heightExtension, 1);
            y_right = linspace(y_half_circle(end), y_half_circle(end) - heightExtension, heightExtension)';
            x_top = linspace(x_left(1), x_right(1), numPoints)';
            y_top = repmat(y_left(end), numPoints, 1);

            % Combine capsule shape
            x_capsule = [x_left; x_half_circle'; x_right; flipud(x_top)];
            y_capsule = [y_left; y_half_circle'; y_right; flipud(y_top)];
            plot(x_capsule, y_capsule, 'r-', 'LineWidth', 1); % Red outline
        end

        % Save the ROI-outlined frame to the directory
        saveas(fig, fullfile(roiDir, sprintf('frame_%03d_roi.png', frame_id)));

        % Close the figure to free up memory
        close(fig);
    end

    fprintf('ROI-outlined frames saved to: %s\n', roiDir);
end
