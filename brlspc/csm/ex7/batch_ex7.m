clear; clc; close all;

outdir = './brlspc/csm/ex7/results';
seed = 42;

run_ex7(struct('type','ones'), seed, outdir);
run_ex7(struct('type','linear'), seed, outdir);
run_ex7(struct('type','poly','degree',2), seed, outdir);
run_ex7(struct('type','rbf','sigma',1e3,'q',1), seed, outdir);
