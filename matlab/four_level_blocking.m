clear; clc;
delete four_level_blocking.txt;
diary four_level_blocking.txt;
%% Build base design
design = zeros(32,8);
% Basic factors a to e
for i=[1,2,3,4,5]
    a = 2^(5-i);
    b = 2^(i-1);
    design(:,i) = repmat([repelem(-1,a),repelem(1,a)],1,b);
end
% Factor f = abcde
design(:,6) = prod(design(:,[1,2,3,4,5]),2);
% Factor g = abe
design(:,7) = prod(design(:,[1,2,5]),2);
% Factor h = abc
design(:,8) = prod(design(:,[1,2,3]),2);

%% All TFI of the base design
tfi = zeros(32,nchoosek(8,2));
% All pairs of factors a to h
combs = nchoosek(1:8, 2);
for i=1:nchoosek(8,2)
    tfi(:,i) = prod(design(:,combs(i,:)),2);
end

thfi = zeros(32,nchoosek(8,3));
% All pairs of factors a to h
combs = nchoosek(1:8, 3);
for i=1:nchoosek(8,3)
    thfi(:,i) = prod(design(:,combs(i,:)),2);
end

%% Pseudo-factors for the columns
% Matrix of the 7 pseudo-factors
pf = zeros(32,3);
% p1 = ab
pf(:,1) = prod(design(:,[1,2]),2);
% p2 = acd
pf(:,2) = prod(design(:,[1,3,4]),2);
% p3 = p1 *p2
pf(:,3) = prod(pf(:,[1,2]),2);

%% Build the whole factorial effect matrix
% All ME, all 2FI , all 3TFI and all PF
factorial_effects = [design, pf, tfi, thfi];

%% Build vector with names
names = [[char(96 + (1:8))', blanks(8)', blanks(8)']; % ME names
    [repmat('p',3,1), char(48 + (1:3))', blanks(3)'] % PF names
    [char(nchoosek(96 + (1:8)', 2)), blanks(nchoosek(8,2))']; %TFI names
    char(nchoosek(96 + (1:8)', 3))]; %3FI names

%% Compute interaction between ME, 2FI, 3FI and PF for column positions
interaction = [design, pf, tfi, thfi]' * factorial_effects;
% There are 8 + 28 + 56 = 92 factorial effects + 3 PF effects and 31
% degrees of freedom so there will be 95-31=64 alias covered
alias_covered = zeros(1,size(factorial_effects,2)-31);
alias_index = 1;
for i=1:size(interaction,1)
    % Check if effect was already covered
    if ismember(i, alias_covered)
        continue
    end
    % Print the name of the effect
    fprintf('%s = ', names(i,:));
    % Find its aliases
    alias = find(interaction(i,:) == 32);
    % Remove alias with itself
    alias = alias(alias ~= i);
    % Add to alias covered
    alias_covered(1,alias_index: alias_index+size(alias,2)-1) = alias;
    alias_index = alias_index + size(alias, 2);
    for j=1:size(alias,2)
        fprintf(names(alias(1,j),:));
        % No '+' printed at the end of the line
        if j < size(alias, 2)
            fprintf(' + ');
        end
    end
    fprintf('\n');
end
fprintf('\n')
%% Retrieve the unique factorial effects into a single matrix
unique_effects_index = ~ismember(1:size(interaction,2), alias_covered);
unique_effects = factorial_effects(:,unique_effects_index);
unique_effects_names = names(unique_effects_index',:);

%% Define the categorical WEEK, PLATE and TUBE factors
% Week is defined as b2=abc
week = (prod(design(:,[1,2,3]), 2)+1)./2;
% Plate is defined as b1=abe * b2=abc
plate = prod(design(:,[1,2,5]), 2)+1+(prod(design(:,[1,2,3]), 2)+1)./2;
% Tube is defined as b2=abc*a*b*d
tube = (prod(design(:,[1,2,3]), 2)+1).*4 +(design(:,1)+1).*2 + (design(:,2)+1) + (design(:,4)+1)./2;

%% Fit a model of the factorial effects ~ WEEK + PLATE + TUBE
X = [week, plate, tube];
% remove the Rank deficient matrix warning
warning('off','stats:LinearModel:RankDefDesignMat');
for i=1:31
    effect_name = unique_effects_names(i,:);
    effect = unique_effects(:,i);
    strata = ['Week ';'Plate';'Tube ';'Unit '];
    mdl = fitlm(X,effect,'CategoricalVars',[1,2,3],'VarNames',{'Week','Plate','Tube',effect_name});
    aov = anova(mdl);
    ss_index = find(aov.SumSq == max(aov.SumSq));
    stratum = strata(ss_index,:);
    fprintf('%s = %s\n',effect_name,stratum);
end
diary off;