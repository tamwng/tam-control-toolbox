function rows = study6_store(output,folder,key,out,q)
%STUDY6_STORE Full paths plus compact summaries; source archives are read only.
checks = study6_check(out,q);
save(fullfile(output,folder,[char(key),'.mat']),'out','q','checks');
rows = study6_summary(out,q);
end
