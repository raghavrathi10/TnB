% Copyright (c) 2016, Nathanael C. Yoder
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

function [ s, t ] = lora_chirp(fc, mu, BW, SF, k, phi0, OSF)
	N = 2^SF*OSF;
	fs = BW*OSF;
	Ts = 1/fs;
	T = N*Ts;
	t = (-N/2:N/2-1)*Ts;
	k = floor(k);
	phi=zeros(1,N);
	t1 = t(1:k*OSF);
	t2 = t((k*OSF+1):N);
	if k>0
		phi(1:k*OSF) = -k*mu/2+3*BW*T*mu/8+BW*mu*t1-k*mu*t1/T+BW*mu*t1.^2/(2*T);
	end
	phi((k*OSF+1):N) = +k*mu/2-BW*T*mu/8-k*mu*t2/T+BW*mu*t2.^2/(2*T);
	s=exp(1i*(phi0+2*pi*phi));
	t = t+T/2;

    if 0
    C = s;
    CZZ = exp([0:length(C)-1]/length(C)*2*pi*i);
    THRESH = 0.35;
    GMAT = zeros(N);
    for h=1:N
        tempp = C(h) - CZZ;
        tempp1 = find(abs(tempp)<THRESH);
        GMAT(h,tempp1) = 1;
    end
    cap0 = zeros(2*N);
    for h=1:N
        for hh=1:N
            if GMAT(h,hh)
                cap0(h,hh+N) = 1;
            end
        end
    end
    cap0;
    cap = zeros(2*N+2);
    cap(1,2:N+1) = 1;
    cap(N+2:2*N+1,end) = 1;
    cap(2:2*N+1,2:2*N+1) = cap0;
    [f, residualg] = fordfulkerson(1,2*N+2,cap);
    
    resg = residualg(2:2*N+1,2:2*N+1);
    match = zeros(1,N);
    for h=1:N
        tempp = find(resg(h+N,:) == 1);
        match(tempp) = h;
    end
    appC = CZZ(match);
    s = appC;
    end
