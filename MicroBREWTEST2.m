function MicroBREWTEST2(imageName, numFrames, outFile)
    % Read the video
    video = VideoReader(imageName);

    % Preallocate
    signals = zeros(numFrames, 1);

    for k = 1:numFrames
        % Read frame
        frame = readFrame(video);

        % Convert to grayscale if needed
        if size(frame,3) == 3
            frameGray = rgb2gray(frame);
        else
            frameGray = frame;
        end

        % --- Step 1: Find centroid of chip ---
        BW = imbinarize(frameGray);              
        stats = regionprops(BW, 'Centroid');     
        c = stats(1).Centroid;                   

        % --- Step 2: Define triangle ROI (static shape near centroid) ---
        vertices = [c(1)+12, c(2)+6;
                    c(1)+50, c(2)-10;
                    c(1)+50, c(2)-42;
                    c(1)+5,  c(2)-42;
                    c(1)+5, c(2)-4];    

        % Create mask
        mask = poly2mask(vertices(:,1), vertices(:,2), size(frameGray,1), size(frameGray,2));

        % --- Step 3: Extract mean intensity inside ROI ---
        signals(k) = mean(frameGray(mask));

        % --- Simple ROI preview
        % ---**************************************************************
        imshow(frame); hold on;
        plot([vertices(:,1); vertices(1,1)], [vertices(:,2); vertices(1,2)], 'r-', 'LineWidth', 2);
        plot(c(1), c(2), 'b+', 'MarkerSize', 10, 'LineWidth', 2);
        title(sprintf('Frame %d', k));
        hold off;
        drawnow;
        %***********************************************************************
    end

    % --- Step 4: Save results as CSV ---
    FrameID = (1:numFrames)';      % column vector of frame numbers
    T = table(FrameID, signals, 'VariableNames', {'FrameID','Signal'});
    writetable(T, outFile);

    fprintf('✅ Signals saved to %s\n', outFile);
end
