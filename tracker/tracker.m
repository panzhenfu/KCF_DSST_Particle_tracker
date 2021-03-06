function [positions, time] = tracker(params)
%   This function implements the pipeline for tracking with motion state estimation 
%   and scale estimation.
%   It is meant to be called by the interface function RUN_TRACKER, which
%   sets up the parameters and loads the video information.
%   Outputs:
%    POSITIONS is an Nx2 matrix of target positions over time (in the
%     format [rows, columns]).
%    TIME is the tracker execution time, without video loading/rendering.
%
%   潘振福 华北电力大学, 2016

       video_path = params.video_path;
       img_files = params.img_files;
       pos = params.init_pos;
       padding = params.padding;
       target_sz = params.wsize;
       kernel = params.kernel;
       lambda = params.lambda;
       output_sigma_factor = params.output_sigma_factor;
       interp_factor = params.interp_factor;
       cell_size = params.cell_size;
       features = params.features;
       show_visualization = params.show_visualization;  
       %scales params---
       nScales = params.number_of_scales;
       scale_step = params.scale_step;
       scale_sigma_factor = params.scale_sigma_factor;
       scale_model_max_area = params.scale_model_max_area;
       
       particleNum = 3;
       
	%if the target is large, lower the resolution, we don't need that much
	%detail
	resize_image = (sqrt(prod(target_sz)) >= 100);  %diagonal size >= threshold
	if resize_image,
		pos = floor(pos / 2);
		target_sz = floor(target_sz / 2);
    end

    init_target_sz = target_sz;

% target size att scale = 1
    base_target_sz = target_sz;

	%window size, taking padding into account
	window_sz = floor(target_sz * (1 + padding));
	
% 	%we could choose a size that is a power of two, for better FFT
% 	%performance. in practice it is slower, due to the larger window size.
% 	window_sz = 2 .^ nextpow2(window_sz);

	
	%create regression labels, gaussian shaped, with a bandwidth
	%proportional to target size
	output_sigma = sqrt(prod(target_sz)) * output_sigma_factor / cell_size;
	yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / cell_size)));

	%store pre-computed cosine window
	cos_window = hann(size(yf,1)) * hann(size(yf,2))';	
    % desired scale filter output (gaussian shaped), bandwidth proportional to
    % number of scales
    scale_sigma = nScales/sqrt(33) * scale_sigma_factor;
    ss = (1:nScales) - ceil(nScales/2);
    ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
    ysf = single(fft(ys));

    % store pre-computed scale filter cosine window
    if mod(nScales,2) == 0
        scale_window = single(hann(nScales+1));
        scale_window = scale_window(2:end);
    else
        scale_window = single(hann(nScales));
    end;

    % scale factors
    ss = 1:nScales;
    scaleFactors = scale_step.^(ceil(nScales/2) - ss);

    % compute the resize dimensions used for feature extraction in the scale
    % estimation
    scale_model_factor = 1;
    if prod(init_target_sz) > scale_model_max_area
        scale_model_factor = sqrt(scale_model_max_area/prod(init_target_sz));
    end
    scale_model_sz = floor(init_target_sz * scale_model_factor);

    currentScaleFactor = 1;

    % to calculate precision
    positions = zeros(numel(img_files), 4);%to calculate precision

    % find maximum and minimum scales
    im = imread([video_path img_files{1}]);
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ window_sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ base_target_sz)) / log(scale_step));
	
	if show_visualization,  %create video interface
		update_visualization = show_video(img_files, video_path, resize_image);
    end
	%note: variables ending with 'f' are in the Fourier domain.
	time = 0;  %to calculate FPS
    %________initial particle set_________
    St = particle_init(pos,particleNum);
    Velocity = zeros(1,2);
    maxPSR = 0;
    maxPSRIndex =1;
	for frame = 1:numel(img_files),
		%load image
		im = imread([video_path img_files{frame}]);
		if size(im,3) > 1,
			im = rgb2gray(im);
		end
		if resize_image,
			im = imresize(im, 0.5);
		end

		tic()

		if frame > 1,
            %______________
            St = particle_reselect(St,particleNum);
            St = particle_propagate(St,particleNum,Velocity);
            for i = 1:particleNum,
			%obtain a subwindow for detection at the position from last
			%frame, and convert to Fourier domain (its size is unchanged)
			patch = get_subwindow(im, St(i).pos,floor(window_sz * currentScaleFactor));
            %mexresize+++++++++++++++++++++++++++++++++++++++++++
            % resize image to model size
             patch = mexResize(patch, window_sz, 'auto');
			zf = fft2(get_features(patch, features, cell_size, cos_window));
			
			%calculate response of the classifier at all shifts
			kzf = gaussian_correlation(zf, model_xf, kernel.sigma);
			response = real(ifft2(model_alphaf .* kzf));  %equation for fast detection
                %___--compute psr
                g_max = max(response(:));
               St(i).psr = g_max;
                if St(i).psr>maxPSR,
                    maxPSR = St(i).psr;
                    maxPSRIndex = i;
                end
			%target location is at the maximum response. we must take into
			%account the fact that, if the target doesn't move, the peak
			%will appear at the top-left corner, not at the center (this is
			%discussed in the paper). the responses wrap around cyclically.
			[vert_delta, horiz_delta] = find(response == max(response(:)), 1);
			if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis
				vert_delta = vert_delta - size(zf,1);
			end
			if horiz_delta > size(zf,2) / 2,  %same for horizontal axis
				horiz_delta = horiz_delta - size(zf,2);
            end
             St(i).pos = St(i).pos + cell_size * [vert_delta - 1, horiz_delta - 1];
          end
               maxPSR = 0.0;
                pos_0 = pos;
	            pos = St(maxPSRIndex).pos;
                Velocity = pos - pos_0;
               % extract the test sample feature map for the scale filter
            xs = get_scale_sample(im, pos, base_target_sz, currentScaleFactor * scaleFactors, scale_window, scale_model_sz);

            % calculate the correlation response of the scale filter
            xsf = fft(xs,[],2);
            scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + lambda)));

            % find the maximum scale response
            recovered_scale = find(scale_response == max(scale_response(:)), 1);
            % update the scale
            currentScaleFactor = currentScaleFactor * scaleFactors(recovered_scale);
            if currentScaleFactor < min_scale_factor
                currentScaleFactor = min_scale_factor;
            elseif currentScaleFactor > max_scale_factor
                currentScaleFactor = max_scale_factor;
            end
		end

		%obtain a subwindow for training at newly estimated target position
		patch = get_subwindow(im, pos, floor(window_sz * currentScaleFactor));
        %mexresize
        patch = mexResize(patch, window_sz, 'auto');
		xf = fft2(get_features(patch, features, cell_size, cos_window));

		%Kernel Ridge Regression, calculate alphas (in Fourier domain)
			kf = gaussian_correlation(xf, xf, kernel.sigma);
		alphaf = yf ./ (kf + lambda);   %equation for fast training      
        % extract the training sample feature map for the scale filter
        xs = get_scale_sample(im, pos, base_target_sz, currentScaleFactor * scaleFactors, scale_window, scale_model_sz);

        % calculate the scale filter update
        xsf = fft(xs,[],2);
        new_sf_num = bsxfun(@times, ysf, conj(xsf));
        new_sf_den = sum(xsf .* conj(xsf), 1);
        
		if frame == 1,  %first frame, train with a single image
			model_alphaf = alphaf;
			model_xf = xf;
            
            sf_den = new_sf_den;
            sf_num = new_sf_num;
        else
			model_alphaf = (1 - interp_factor) * model_alphaf + interp_factor * alphaf;
			model_xf = (1 - interp_factor) * model_xf + interp_factor * xf;
            
            sf_den = (1 - interp_factor) * sf_den + interp_factor * new_sf_den;
            sf_num = (1 - interp_factor) * sf_num + interp_factor * new_sf_num;
        end
        
    % calculate the new target size
    target_sz = floor(base_target_sz * currentScaleFactor);
    %save position
    positions(frame,:) = [pos target_sz];
		%save position and timing
		time = time + toc();

		%visualization
		if show_visualization,
			box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
			stop = update_visualization(frame, box);
			if stop, break, end  %user pressed Esc, stop early
			
			drawnow
% 			pause(0.05)  %uncomment to run slower
		end
		
	end

	if resize_image,
		positions = positions * 2;
	end
end

