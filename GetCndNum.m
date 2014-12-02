function nout = GetCndNumber(nin)
% put high bite first, low bite second, subtract 1000
nout = hex2dec([dec2hex(nin(2),2),dec2hex(nin(1),2)])-1000;