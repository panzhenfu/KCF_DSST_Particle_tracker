# KCF_DSST_Particle_tracker

             运动状态与尺度空间估计的视觉目标跟踪方法

             潘振福 朱永利 华北电力大学

________________
Will be published.

This MATLAB code implements a simple tracking pipeline with motion estimation and scale estimation .
__________
Quickstart

1. Extract code somewhere.

2. The tracker is prepared to run on any of the 50 videos of the Visual Tracking
   Benchmark [3]. For that, it must know where they are/will be located. You can
   change the default location 'base_path' in 'download_videos.m' and 'run_tracker.m'.

3. If you don't have the videos already, run 'download_videos.m' (may take some time).

4. Execute 'run_tracker' without parameters to choose a video and test the tracker on it.


Note: The tracker uses the 'fhog'/'gradientMex' functions from Piotr's Toolbox.
Some pre-compiled MEX files are provided for convenience. If they do not work for your
system, just get the toolbox from http://vision.ucsd.edu/~pdollar/toolbox/doc/index.html


__________

The main interface function is 'run_tracker'. You can test it by calling it with different commands:


 run_tracker
   Without any parameters, will ask you to choose a video, and show the results in an interactive
   figure. Press 'Esc' to stop the tracker early. You can navigate the
   video using the scrollbar at the bottom.

 run_tracker VIDEO
   Allows you to select a VIDEO by its name. 'all' will run all videos
   and show average statistics. 'choose' will select one interactively.


 run_tracker(VIDEO, SHOW_VISUALIZATION, SHOW_PLOTS)
   Decide whether to show the scrollable figure, and the precision plot.

 Useful combinations:
 >> run_tracker choose    %choose the video to test the traker
 >> run_tracker all       %test all the vodeo on the path files

For the actual tracking code, check out the 'tracker' function.

Though it's not required, the code will make use of the MATLAB Parallel Computing
Toolbox automatically if available.


__________
References

[1] J. F. Henriques, R. Caseiro, P. Martins, J. Batista, "High-Speed Tracking with
Kernelized Correlation Filters", TPAMI 2014 (to be published).

[2] J. F. Henriques, R. Caseiro, P. Martins, J. Batista, "Exploiting the Circulant
Structure of Tracking-by-detection with Kernels", ECCV 2012.

[3] Y. Wu, J. Lim, M.-H. Yang, "Online Object Tracking: A Benchmark", CVPR 2013.
Website: http://visual-tracking.net/

[4] P. Dollar, "Piotr's Image and Video Matlab Toolbox (PMT)".
Website: http://vision.ucsd.edu/~pdollar/toolbox/doc/index.html

[5] P. Dollar, S. Belongie, P. Perona, "The Fastest Pedestrian Detector in the
West", BMVC 2010.


_____________________________________
Copyright (c) 2016, panzhenfu (潘振福)华北电力大学 

Permission to use, copy, modify, and distribute this software for research
purposes with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
