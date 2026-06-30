clear; clc; close all;

outdir = './brlspc/csm/ex6/results';
seed = 42;

run_ex6(struct('type','ones'), seed, outdir);
run_ex6(struct('type','linear'), seed, outdir);
run_ex6(struct('type','poly','degree',2), seed, outdir);
run_ex6(struct('type','rbf','sigma',1e3,'q',1), seed, outdir);
