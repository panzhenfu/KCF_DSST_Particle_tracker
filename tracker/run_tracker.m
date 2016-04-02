
%  运动状态与尺度空间估计的视觉目标跟踪方法
%
%  潘振福,华北电力大学 2016
%  our work is based on Joao F. Henriques’work in paper High-Speed Tracking with Kernelized Correlation Filters
%  This function takes care of setting up parameters, loading video
%  information and computing precisions. For the actual tracking code,
%  check out the TRACKER function.
%
%  RUN_TRACKER
%    Without any parameters, will ask you to choose a video, track using
%    the Gaussian KCF on HOG, and show the results in an interactive
%    figure. Press 'Esc' to stop the tracker early. You can navigate the
%    video using the scrollbar at the bottom.
%
%  RUN_TRACKER VIDEO
%    Allows you to select a VIDEO by its name. 'all' will run all videos
%    and show average statistics. 'choose' will select one interactively.
%
%  RUN_TRACKER(VIDEO, SHOW_VISUALIZATION, SHOW_PLOTS)
%    Decide whether to show the scrollable figure, and the precision plot.
%
%  Useful combinations:
%  >> run_tracker choose   %choose the video to test the tracker
%  >> run_tracker all      %take all videos to test the tracker on path 

function [precision, fps] = run_tracker(video,show_visualization, show_plots)
	%path to the videos (you'll be able to choose one with the GUI).
	base_path = './data/Benchmark/';

	%default settings
	if nargin < 1, video = 'choose'; end
 	if nargin < 2, show_visualization = ~strcmp(video, 'all'); end
 	if nargin < 3, show_plots = ~strcmp(video, 'all'); end


	%parameters according to the paper. at this point we can override
	%parameters based on the chosen kernel or feature type
	kernel.type = 'gaussian';
	
	padding = 1.5;  %extra area surrounding the target
	lambda = 1e-4;  %regularization
	output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)

		interp_factor = 0.025;
		
		kernel.sigma = 0.5;
		
		kernel.poly_a = 1;
		kernel.poly_b = 9;
		
		features.hog = true;
		features.hog_orientations = 9;
		cell_size = 4;



	switch video
	case 'choose',
		%ask the user for the video, then call self with that video name.
		video = choose_video(base_path);
		if ~isempty(video),
			[precision, fps] = run_tracker(video, show_visualization, show_plots);
			
			if nargout == 0,  %don't output precision as an argument
				clear precision
			end
		end
		
		
	case 'all',
		%all videos, call self with each video name.
		
		%only keep valid directory names
		dirs = dir(base_path);
		videos = {dirs.name};
		videos(strcmp('.', videos) | strcmp('..', videos) | ...
			strcmp('anno', videos) | ~[dirs.isdir]) = [];
		
		%the 'Jogging' sequence has 2 targets, create one entry for each.
		%we could make this more general if multiple targets per video
		%becomes a common occurence.
		videos(strcmpi('Jogging', videos)) = [];
		videos(end+1:end+2) = {'Jogging.1', 'Jogging.2'};
		
		all_precisions = zeros(numel(videos),1);  %to compute averages
		all_fps = zeros(numel(videos),1);
		
		if ~exist('matlabpool', 'file'),
			%no parallel toolbox, use a simple 'for' to iterate
			for k = 1:numel(videos),
				[all_precisions(k), all_fps(k)] = run_tracker(videos{k},show_visualization, show_plots);
			end
		else
			%evaluate trackers for all videos in parallel
			if matlabpool('size') == 0,
				matlabpool open;
			end
			parfor k = 1:numel(videos),
				[all_precisions(k), all_fps(k)] = run_tracker(videos{k},show_visualization, show_plots);
			end
		end
		
		%compute average precision at 20px, and FPS
		mean_precision = mean(all_precisions);
		fps = mean(all_fps);
		fprintf('\nAverage precision (20px):% 1.3f, Average FPS:% 4.2f\n\n', mean_precision, fps)
		if nargout > 0,
			precision = mean_precision;
		end
		
		
% 	case 'benchmark',
% 		%running in benchmark mode - this is meant to interface easily
% 		%with the benchmark's code.
% 		
% 		%get information (image file names, initial position, etc) from
% 		%the benchmark's workspace variables
% 		seq = evalin('base', 'subS');
% 		target_sz = seq.init_rect(1,[4,3]);
% 		pos = seq.init_rect(1,[2,1]) + floor(target_sz/2);
% 		img_files = seq.s_frames;
% 		video_path = [];
% 		
% 		%call tracker function with all the relevant parameters
% 		positions = tracker(video_path, img_files, pos, target_sz, ...
% 			padding, kernel, lambda, output_sigma_factor, interp_factor, ...
% 			cell_size, features, false);
% 		
% 		%return results to benchmark, in a workspace variable
% 		rects = [positions(:,2) - target_sz(2)/2, positions(:,1) - target_sz(1)/2];
% 		rects(:,3) = target_sz(2);
% 		rects(:,4) = target_sz(1);
% 		res.type = 'rect';
% 		res.res = rects;
% 		assignin('base', 'res', res);
		
		
	otherwise
		%we were given the name of a single video to process.
	
		%get image file names, initial state, and ground truth for evaluation
		[img_files, pos, target_sz, ground_truth, video_path] = load_video_info(base_path, video);
		
%parameters according to the paper
       params.video_path = video_path;
       params.img_files = img_files;
       params.init_pos = pos;%floor(pos) + floor(target_sz/2);
       params.wsize = floor(target_sz);
       params.padding = padding;         			% extra area surrounding the target
       params.kernel = kernel;
       params.lambda = lambda;					% regularization weight (denoted "lambda" in the paper)
       params.output_sigma_factor = output_sigma_factor;% standard deviation for the desired translation filter output
       params.interp_factor = interp_factor;
       params.cell_size = cell_size;
       params.features = features;
       params.show_visualization = show_visualization;
       %_____-scale params
      params.scale_sigma_factor = 1/3;        % standard deviation for the desired scale filter output
      params.learning_rate = 0.030;			% tracking model learning rate (denoted "eta" in the paper)
      params.number_of_scales = 33;           % number of scale levels (denoted "S" in the paper)
      params.scale_step = 1.02;               % Scale increment factor (denoted "a" in the paper)
      params.scale_model_max_area = 512;      % the maximum size of scale examples
%————————————————————————
		%call tracker function with all the relevant parameters
		%[positions, time] = tracker(video_path, img_files, pos, target_sz, ...
		%	padding, kernel, lambda, output_sigma_factor, interp_factor, ...
		%	cell_size, features, show_visualization);
		[positions, time] = tracker(params);
		
		%calculate and show precision plot, as well as frames-per-second
		precisions = precision_plot(positions, ground_truth, video, show_plots);
		fps = numel(img_files) / time;

		fprintf('%12s - Precision (20px):% 1.3f, FPS:% 4.2f\n', video, precisions(20), fps)

		if nargout > 0,
			%return precisions at a 20 pixels threshold
			precision = precisions(20);
		end

	end
end
