clear; clc; close all;

outdir = './brlspc/csm/ex3/results';
seed = 42;

run_ex3(struct('type','ones'), seed, outdir);
run_ex3(struct('type','linear'), seed, outdir);
run_ex3(struct('type','rbf','sigma',1e3,'q',1), seed, outdir);
