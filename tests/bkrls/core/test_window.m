classdef test_window < matlab.unittest.TestCase
    % Unit tests for bkrls/window.m
    % Focus: indexing, readiness, status codes, get/reset behavior, SISO+MIMO

    methods (Test)
        function testInitDefaults(tc)
            p=2; m=3; ell=4;
            st = window('init',p,m,ell);
            tc.verifyEqual(st.p, double(p));
            tc.verifyEqual(st.m, double(m));
            tc.verifyEqual(st.ell, double(ell));
            tc.verifyTrue(all(isnan(st.y_hist), 'all'));
            tc.verifyTrue(all(isnan(st.u_hist), 'all'));
            tc.verifyEqual(st.nY, 0);
            tc.verifyEqual(st.nU, 0);
            tc.verifyEqual(st.t, 0);
            tc.verifyTrue(st.assert);
            tc.verifyGreaterThan(st.eps, 0);
        end

        function testPushReadinessAndAlignmentSISO(tc)
            p=1; m=1; ell=2;
            st = window('init',p,m,ell);
            u = [1;2;3;4];  y = [10;20;30;40];
        
            for k=1:numel(u)
                [st,s,ready,status] = window('push',st,u(k),y(k));
                if k<=ell
                    tc.verifyFalse(ready);
                    tc.verifyFalse(status.ok);
                    tc.verifyEqual(status.code,'NOT_READY');
                else
                    tc.verifyTrue(ready);
                    tc.verifyTrue(status.ok);
                    tc.verifyEqual(s.u(1), u(k));      % u_k
                    tc.verifyEqual(s.u(2), u(k-1));    % u_{k-1}
                    tc.verifyEqual(s.y(1), y(k-1));    % excludes y_k
                end
            end
            tc.verifyEqual(st.t, numel(u));
        end

        function testAlignmentMIMO(tc)
            p=2; m=3; ell=3;
            st = window('init',p,m,ell);
            U = (1:5*m).'; U = reshape(U, m, []); U=U.';   % 5×m then feed row-wise
            Y = (101:101+5*p-1).'; Y = reshape(Y, p, []).'; % 5×p

            for k=1:size(U,1)
                u_k = U(k,:).'; y_k = Y(k,:).';
                [st, s, ready, ~] = window('push', st, u_k, y_k);
                if k>ell
                    tc.verifyTrue(ready);
                    tc.verifyEqual(s.u(:,1), u_k);           % direct feedthrough
                    tc.verifyEqual(s.y(:,1), Y(k-1,:).');    % previous output
                    tc.verifySize(s.y, [p, ell]);
                    tc.verifySize(s.u, [m, ell+1]);
                end
            end
        end

        function testNotReadyNaNPattern(tc)
            p=1; m=1; ell=3;
            st = window('init',p,m,ell);
        
            [st,s1,ready1,status1] = window('push',st,5,50);
            tc.verifyFalse(ready1);
            tc.verifyFalse(status1.ok);
            tc.verifyEqual(status1.code,'NOT_READY');
            tc.verifyTrue(all(isnan(s1.y),'all'));      % scalar check
            tc.verifyTrue(all(isnan(s1.u(:,3:4)),'all'));
        
            [st,s2,ready2,~] = window('push',st,6,60);
            tc.verifyFalse(ready2);
            tc.verifyEqual(s2.u(1),6);
            tc.verifyEqual(s2.u(2),5);
            tc.verifyTrue(all(isnan(s2.u(:,3:4)),'all'));
        end

        function testBadDimStatusAndNoCommit(tc)
            p=2; m=1; ell=2;
            st = window('init',p,m,ell);
            st_before = st;
            % Wrong y_k shape
            [st_after, s, ready, status] = window('push', st, 1, 1); % y_k should be 2×1
            tc.verifyFalse(status.ok);
            tc.verifyEqual(status.code, 'BAD_DIM');
            tc.verifyFalse(ready);
            tc.verifyEmpty(s.y);
            tc.verifyEmpty(s.u);
            % State unchanged
            tc.verifyTrue(isequaln(st_after.y_hist, st_before.y_hist));
            tc.verifyTrue(isequaln(st_after.u_hist, st_before.u_hist));
            tc.verifyEqual(st_after.t, st_before.t);
            tc.verifyEqual(st_after.nY, st_before.nY);
            tc.verifyEqual(st_after.nU, st_before.nU);
        end

        function testNaNInputStatusAndNoCommit(tc)
            p=1; m=1; ell=2;
            st = window('init',p,m,ell);
            st_before = st;
            [st_after, s, ready, status] = window('push', st, NaN, 1);
            tc.verifyFalse(status.ok);
            tc.verifyEqual(status.code, 'NAN_INPUT');
            tc.verifyFalse(ready);
            tc.verifyEmpty(s.y);
            tc.verifyEmpty(s.u);
            tc.verifyTrue(isequaln(st_after.y_hist, st_before.y_hist));
            tc.verifyTrue(isequaln(st_after.u_hist, st_before.u_hist));
            tc.verifyEqual(st_after.t, st_before.t);
        end

        function testGetReturnsCurrentTemplate(tc)
            p=1; m=1; ell=2;
            st = window('init',p,m,ell);
            [st, ~, ~, ~] = window('push', st, 3, 30); % k=1
            [st, ~, ~, ~] = window('push', st, 4, 40); % k=2
            [s, ready] = window('get', st);
            tc.verifyTrue(ready==true);  % history full after second push
            % get returns y_hist with y_k at column 1 and u_hist with u_k at column 1
            tc.verifyEqual(s.y(1), 40);
            tc.verifyEqual(s.u(1), 4);
        end

        function testResetClearsState(tc)
            p=2; m=1; ell=2;
            st = window('init',p,m,ell);
            [st, ~, ~, ~] = window('push', st, 1, [10; 20]);
            [st, ~, ~, ~] = window('push', st, 2, [30; 40]);
            st = window('reset', st);
            tc.verifyTrue(all(isnan(st.y_hist),'all'));
            tc.verifyTrue(all(isnan(st.u_hist),'all'));
            tc.verifyEqual(st.nY, 0);
            tc.verifyEqual(st.nU, 0);
            tc.verifyEqual(st.t, 0);
            [s, ready] = window('get', st);
            tc.verifyFalse(ready);
            tc.verifyTrue(all(isnan(s.y),'all'));
            tc.verifyTrue(all(isnan(s.u),'all'));
        end

        function testEdgeCaseEllOne(tc)
            p=1; m=1; ell=1;
            st = window('init',p,m,ell);
            [st, s, r1, ~] = window('push', st, 7, 70); % k=1
            tc.verifyFalse(r1);
            tc.verifyTrue(isnan(s.y(1)));
            [~, s2, r2, ~] = window('push', st, 8, 80); % k=2
            tc.verifyTrue(r2);
            tc.verifyEqual(s2.u(1), 8);
            tc.verifyEqual(s2.y(1), 70);
        end

        function testTimeCounterIncrementsOnlyOnOK(tc)
            p=1; m=1; ell=2;
            st = window('init',p,m,ell);
        
            % First push: not ready yet
            [st, ~, ready1, status1] = window('push', st, 1, 10);
            tc.verifyFalse(ready1);
            tc.verifyFalse(status1.ok);
            tc.verifyEqual(status1.code, 'NOT_READY');
            tc.verifyEqual(st.t, 1);  % t increments anyway (sample processed)
        
            % Wrong dimension push
            [st2, ~, ~, status2] = window('push', st, [2;3], 20);
            tc.verifyFalse(status2.ok);
            tc.verifyEqual(st2.t, st.t); % no increment on BAD_DIM
        
            % Push until ready
            [st3, ~, ready3, status3] = window('push', st2, 2, 20);
            if ready3
                tc.verifyTrue(status3.ok);
            else
                tc.verifyFalse(status3.ok);
                tc.verifyEqual(status3.code,'NOT_READY');
            end
        end
    end
end
