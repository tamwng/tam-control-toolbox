% batch_ex2b.m
% Runs Example 2b once per kernel and saves results under ./results

clear; clc; close all;

outdir = './brlspc/csm/ex2/ex2b/results';
seed = 42;

db_amp = [0.1, 0.5, 1];
ell = [2, 3, 4, 5];
for i = 1:length(db_amp)
    for j = 1:length(ell)
        run_ex2b_kernel(struct('type','ones'), seed, outdir, db_amp(i), ell(j));
        run_ex2b_kernel(struct('type','rbf','sigma',1e3,'q',1), seed, outdir, db_amp(i), ell(j));
    end
end