%TAKESTEP give analytic solution to the Quadratic programming
%  problems and determine whether to update the chosen 
%  variables.
%
%  Main procedure:
%    1.calculate value range for i2;
%    2.calculate new value for i2 and i1;
%    3.update threshold b;
%    4.update error value.
%
%  @date: 10/26/2012
%

function status = takeStep(i1, i2)
% define in other place
global train_set;
global C;
global tolerance;
global eps;
global alpha;
global error_cache;
global tr_ins_num;
global kernel_func;
global b;

if i1 == i2,
    status = 0; return;
end

y1 = train_set.tag(i1);
y2 = train_set.tag(i2);
alpha1_old = alpha(i1);
alpha2_old = alpha(i2);

if alpha1_old>0 & alpha1_old<C,
    E1 = error_cache(i1);
else,
    E1 = learned_func(i1) - y1;
end

if alpha2_old>0 & alpha2_old<C,
    E2 = error_cache(i2);
else,
    E2 = learned_func(i2) - y2;
end

% cal value range for i2
if y1 == y2,
    L = max(0, alpha1_old+alpha2_old-C);
    H = min(C, alpha1_old+alpha2_old);
else,
    temp_diff = alpha2_old-alpha1_old ;
    L = max(0, alpha2_old-alpha1_old);
    H = min(C, C+alpha2_old-alpha1_old);
end

% (C,0) or (0,C)
if L == H,
    status = 0; return ;
end

% 2.calculate new value for i2 and i1;
k11 = kernel_func(train_set.fea(i1,:), train_set.fea(i1,:));
k22 = kernel_func(train_set.fea(i2,:), train_set.fea(i2,:));
k12 = kernel_func(train_set.fea(i1,:), train_set.fea(i2,:));

eta = 2*k12 - k11 - k22;

if eta < 0,
    alpha2_new = alpha2_old + y2*(E2-E1)/eta;
    if alpha2_new < L,
        alpha2_new = L;
    elseif alpha2_new > H,
        alpha2_new = H;
    end
else
    c1 = eta/2;
    c2 = y2*(E1-E2)-eta*alpha2_old;
    lobj_re = c1*L*L+c2*L;
    hobj_re = c1*H*H+c2*H;
    % variation of the objective function value
    if lobj_re > hobj_re + eps,
        alpha2_new = L;
    elseif hobj_re > lobj_re + eps,
        alpha2_new = H;
    else,
        alpha2_new = alpha2_old;
    end
end

% variatio of i2 value
if abs(alpha2_new-alpha2_old)<eps*(alpha2_old+alpha2_new+eps),
    status = 0; return ;
end

% update i1 value
s = train_set.tag(i1)*train_set.tag(i2);
alpha1_new = alpha1_old + s*(alpha2_old - alpha2_new);

if alpha1_new < 0,
    alpha2_new = alpha2_new + s*alpha1_new;
    alpha1_new = 0;
elseif alpha1_new > C,
    alpha2_new = alpha2_new + s*(alpha1_new-C);
    alpha1_new = C;
end

% calculate value of objective function.
[objval_old, objval_new]= objvalue(alpha1_new, i1, alpha2_new, i2);
%fprintf('Old objective value:%f;    New objective value: %f!\n', objval_old, objval_new);

%if abs(objval_new - objval_old)==0,
if objval_new > objval_old,
    status=0; return;
end
%pause;
%if (objval_new - objval_old) < eps,
%    status = 0; return;
%end

% 3.update threshold b (Note:wx-b);
if alpha1_new > 0 & alpha1_new < C,
    bnew = E1 + y1*k11*(alpha1_new-alpha1_old) + y2*k12*(alpha2_new...
        -alpha2_old) + b;
else
    if alpha2_new >0 & alpha2_new < C,
        bnew = E2 + y1*k12*(alpha1_new-alpha1_old) + ...
            y2*k22*(alpha2_new-alpha2_old) + b;
    else
        %Beause two inequalities all includes 1,so b1 and b2 satisfy KKT
        b1 = E1 + y1*k11*(alpha1_new-alpha1_old) + ...
            y2*k12*(alpha2_new-alpha2_old) + b;
        b2 = E2 + y1*k12*(alpha1_new-alpha1_old) + ...
            y2*k22*(alpha2_new-alpha2_old) + b;
        bnew = (b1+b2)/2;
    end
end
delta_b = bnew-b;
b = bnew;

% 4.update error value. use difference to update.
t1 = y1*(alpha1_new - alpha1_old);
t2 = y2*(alpha2_new - alpha2_old);
%for i=1:tr_ins_num,
    % Note!!!update for all train instances
%    error_cache(i) = error_cache(i) + t1*kernel_func(...
%        train_set.fea(i1,:), train_set.fea(i,:)) + t2* ...
%        kernel_func(train_set.fea(i2,:),train_set.fea(i,:))-delta_b;
%end
% Note!!!update for all train instances
error_cache = error_cache + t1*kernel_func(...
    train_set.fea, train_set.fea(i1,:)) + t2* ...
    kernel_func(train_set.fea, train_set.fea(i2,:))-delta_b;

% force
error_cache(i1) = 0;
error_cache(i2) = 0;

alpha(i1) = alpha1_new;
alpha(i2) = alpha2_new;

%disp('Seperating line');
%sp = sum((alpha.*train_set.tag)'*train_set.fea, 1)
%b
%pause;

status = 1; return ;
