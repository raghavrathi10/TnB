% Daniele Croce, Michele Gucciardo, Stefano Mangione, Giuseppe Santaromita, Ilenia Tinnirello:
% Impact of LoRa Imperfect Orthogonality: Analysis of Link-Level Performance. IEEE Commun. Lett. 22(4): 796-799 (2018)

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
