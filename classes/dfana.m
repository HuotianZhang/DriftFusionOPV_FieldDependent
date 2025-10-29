classdef dfana
    % DRIFTFUSION analysis class- contains multiple methods for calculating
    % outputs using the solution obtained from DF.
    %
    %% LICENSE
    % Copyright (C) 2020  Philip Calado, Ilario Gelmetti, and Piers R. F. Barnes
    % Imperial College London
    % This program is free software: you can redistribute it and/or modify
    % it under the terms of the GNU Affero General Public License as published
    % by the Free Software Foundation, either version 3 of the License, or
    % (at your option) any later version.
    %
    %% Start code
    methods (Static)
        function [u,t,x,par,n,p,CT,Ex,V] = splitsol(sol)
            % splits solution into useful outputs
            u = sol.sol;
            t = sol.t;
            x = sol.x;
            par = sol.params;
%             dev = par.dev;
            
            % split the solution into its component parts (e.g. electrons, holes and efield)
            V = u(:,:,4);
            n = u(:,:,1);
            p = u(:,:,2);
            CT = u(:,:,3);
            Ex = u(:,:,5);
            
        end
        function dev = develop(sol)
            par=sol.params;
            x=sol.x;
            xmax=max(x);
            t=sol.t;
            xpoints=length(x);%%%%%%%%%%%%%%%%%%%%carefuld
            dev.xpoints=xpoints;
            for ii=1:1:par.layers_num
                if(par.Experiment_prop.symm==1)
                    BM=ones(length(t), xpoints)*diag(par.Layers{ii}.XL<=x & x <= par.Layers{ii}.XR)+ones(length(t), xpoints)*diag(xmax-par.Layers{ii}.XL>=x & x > xmax-par.Layers{ii}.XR);
                else
                    BM=ones(length(t), xpoints)*diag(par.Layers{ii}.XL<=x & x <= par.Layers{ii}.XR);
                end
                
                for name=fieldnames(par.Layers{ii})'
                    if isfield(dev,name)
                         eval([ 'dev.' char(name) '=dev.' char(name) '+ par.Layers{ii}.' char(name) '*BM ;']);
                    else   
                        eval([ 'dev.' char(name) '= par.Layers{ii}.' char(name) '*BM ;']);
                    end
                    
                end
            end
            
            
        end
        
        function dev = develop_half(sol)
            par=sol.params;
            xmesh=sol.x;
            for i = 1:length(xmesh)-1
                x(i) = xmesh(i)+((xmesh(i+1)-xmesh(i))/2);
            end
            t=sol.t;
            xpoints=length(x);%%%%%%%%%%%%%%%%%%%%carefuld
            dev.xpoints=xpoints;
            for ii=1:1:par.layers_num
                if(par.Experiment_prop.symm==1)
                    BM=ones(length(t), xpoints)*diag(par.Layers{ii}.XL<=x & x <= par.Layers{ii}.XR)+ones(length(t), xpoints)*diag(xmax-par.Layers{ii}.XL>=x & x > xmax-par.Layers{ii}.XR);
                else
                    BM=ones(length(t), xpoints)*diag(par.Layers{ii}.XL<=x & x <= par.Layers{ii}.XR);
                end
                
                for name=fieldnames(par.Layers{ii})'
                    if isfield(dev,name)
                         eval([ 'dev.' char(name) '=dev.' char(name) '+ par.Layers{ii}.' char(name) '*BM ;']);
                    else   
                        eval([ 'dev.' char(name) '= par.Layers{ii}.' char(name) '*BM ;']);
                    end
                    
                end
            end
            
            
        end
            
        function [Ecb, Evb, Efn, Efp] = QFLs(sol)
            % u is the solution structure
            % Simple structure names
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            dev = dfana.develop(sol);
            % Create 2D matrices for multiplication with solutions
           
            Ecb = dev.EA-V;                                 % Conduction band potential
            Evb = dev.IP-V;                                 % Valence band potential
            Efn = real(Ecb+(par.physical_const.kBT/par.physical_const.q)*log(n./dev.N0C));        % Electron quasi-Fermi level
            Efp = real(Evb-(par.physical_const.kBT/par.physical_const.q)*log(p./dev.N0V));        % Hole quasi-Fermi level
            
        end
        
        function [Ecb, Evb, Efn, Efp] = QFL_ihalf(sol)
            % Calculates the QFLs on the i_half xmesh
            % u is the solution structure
            % Simple structure names
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            x = getvarihalf(xmesh);
            for ii = 1:length(t)
                n(ii,:) = getvarihalf(n(ii,:));
                p(ii,:) = getvarihalf(p(ii,:));
                CT(ii,:) = getvarihalf(CT(ii,:));
                Ex(ii,:) = getvarihalf(Ex(ii,:));
                V(ii,:) = getvarihalf(V(ii,:));
            end
            dev_ihalf = par.dev_ihalf;
            
            % Create 2D matrices for multiplication with solutions
            EAmat = repmat(dev_ihalf.EA, length(t), 1);
            IPmat = repmat(dev_ihalf.IP, length(t), 1);
            Ncmat = repmat(dev_ihalf.Nc, length(t), 1);
            Nvmat = repmat(dev_ihalf.Nv, length(t), 1);
            eppmat = repmat(dev_ihalf.epp, length(t), 1);
            nimat = repmat(dev_ihalf.ni, length(t), 1);
            mue_mat = repmat(dev_ihalf.mue, length(t), 1);
            muh_mat = repmat(dev_ihalf.muh, length(t), 1);
            
            Ecb_ihalf = EAmat-V;                                 % Conduction band potential
            Evb_ihalf = IPmat-V;                                 % Valence band potential
            
            if par.prob_distro_function == 'Fermi'
                
                for i = 1:size(n,1)           % time
                    for j = 1:size(n,2)       % position
                        Efn_ihalf(i,j) = distro_fun.Efn_fd_fun(n(i,j), dev.Efn(j,:),  dev.n_fd(j,:));
                        Efp_ihalf(i,j) = distro_fun.Efp_fd_fun(p(i,j), dev.Efp(j,:),  dev.p_fd(j,:));
                    end
                end
                Efn_ihalf = Efn_ihalf-V;
                Efp_ihalf = Efp_ihalf-V;
                
            elseif par.prob_distro_function == 'Boltz'
                Efn_ihalf = real(Ecb_ihalf+(par.physical_const.kBT/par.physical_const.q)*log(n./Ncmat));        % Electron quasi-Fermi level
                Efp_ihalf = real(Evb_ihalf-(par.physical_const.kBT/par.physical_const.q)*log(p./Nvmat));        % Hole quasi-Fermi level
            end
            
            Efn = Efn_ihalf;% zeros(length(t), length(xmesh));
            Efp = Efp_ihalf;% zeros(length(t), length(xmesh));
            Ecb = Ecb_ihalf;
            Evb = Evb_ihalf;

        end
        
        function [Ecb, Evb, Efn, Efp] = QFL_J(sol)
            % u is the solution structure
            % Simple structure names
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            x = getvarihalf(xmesh);
            for ii = 1:length(t)
                n(ii,:) = getvarihalf(n(ii,:));
                p(ii,:) = getvarihalf(p(ii,:));
                CT(ii,:) = getvarihalf(CT(ii,:));
                Ex(ii,:) = getvarihalf(Ex(ii,:));
                V(ii,:) = getvarihalf(V(ii,:));
            end
            
            dev_ihalf = par.dev_ihalf;
            % Create 2D matrices for multiplication with solutions
            EAmat = repmat(dev_ihalf.EA, length(t), 1);
            IPmat = repmat(dev_ihalf.IP, length(t), 1);
            Ncmat = repmat(dev_ihalf.Nc, length(t), 1);
            Nvmat = repmat(dev_ihalf.Nv, length(t), 1);

            eppmat = repmat(dev_ihalf.epp, length(t), 1);
            nimat = repmat(dev_ihalf.ni, length(t), 1);
            mue_mat = repmat(dev_ihalf.mue, length(t), 1);
            muh_mat = repmat(dev_ihalf.muh, length(t), 1);
            
            [J, j, x] = dfana.calcJ(sol);
            for i = 1:length(t)
                deltaEfn(i,:) = cumtrapz(x, J.n(i,:)./(par.e.*mue_mat(i,:).*n(i,:)), 2);
                deltaEfp(i,:) = cumtrapz(x, J.p(i,:)./(par.e.*muh_mat(i,:).*p(i,:)), 2);
            end
            % Boundary values - electrostatic potential is assumed to be
            % zero at left-hand boundary
            %             Efn = zeros(size(n,1), size(n,2));
            %             Efp = zeros(size(n,1), size(n,2));
            
            if par.prob_distro_function == 'Fermi'
                
                for i = 1:size(n,1)           % time
                    for j = 1:size(n,2)       % position
                        Efn_l(i) = distro_fun.Efn_fd_fun(n(i,1), dev_ihalf.Efn(j,1),  dev_ihalf.n_fd(j,1));
                        Efp_l(i) = distro_fun.Efp_fd_fun(p(i,1), dev_ihalf.Efp(j,1),  dev_ihalf.p_fd(j,1));
                    end
                end
                
            elseif par.prob_distro_function == 'Boltz'
                Efn_l = real(par.EA(1)+(par.physical_const.kBT/par.physical_const.q)*log(n(:,1)./Ncmat(:,1)));        % Electron quasi-Fermi level
                Efp_l = real(par.IP(1)-(par.physical_const.kBT/par.physical_const.q)*log(p(:,1)./Nvmat(:,1)));        % Hole quasi-Fermi level
            end
            
            Efn = Efn_l + deltaEfn;
            Efp = Efp_l + deltaEfp;
            
            Ecb = EAmat-V;                                 % Conduction band potential
            Evb = IPmat-V;                                 % Valence band potential
        end
        
        function [J, j, x] = calcJ(sol)
            % Current, J and flux, j calculation from continuity equations
            % Calculated on the i+0.5 grid
            option = 2;
            % obtain SOL components for easy referencing
            [u,t,xmesh,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            
            for ii = 1:length(t)
                n_ihalf(ii,:) = getvarihalf(n(ii,:));
                p_ihalf(ii,:) = getvarihalf(p(ii,:));
                CT_ihalf(ii,:) = getvarihalf(CT(ii,:));
                Ex_ihalf(ii,:) = getvarihalf(Ex(ii,:));
%                  V_ihalf(ii,:) = getvarihalf(V(ii,:));
%                  dVdx(ii,:) = gradient(V_ihalf(ii,:), x);
            end
            for i = 1:length(xmesh)-1
                x(i) = xmesh(i)+((xmesh(i+1)-xmesh(i))/2);
            end
            [FV, ~] = dfana.calcF(sol);
            for i = 1:length(t)
                FV_ihalf(i,:) = interp1(xmesh, FV(i,:), x);
            end
            
            for i = 1:length(x)
                dndt(:,i) = gradient(n_ihalf(:,i), t);
                dpdt(:,i) = gradient(p_ihalf(:,i), t);
                
            end
           
            dev = dfana.develop_half(sol);
            rg = dev.kdis.*exp((abs(FV_ihalf)).*dev.r0_CT./(sol.params.physical_const.kBT)).*CT_ihalf-dev.kfor.*(n_ihalf.*p_ihalf);%-1e8*(n_ihalf.*p_ihalf-dev.ni)./(n_ihalf+p_ihalf);
%             EXfunction= sol.params.light_properties.Genstrength-dev.kdisexc.*(Ex_ihalf)-dev.krecexc.*(Ex_ihalf-dev.Ex0)+dev.kforEx.*(CT_ihalf);
%             CTfunction=dev.kdisexc.*(Ex_ihalf)+dev.kfor.*(n_ihalf.*p_ihalf)-dev.kdis.*exp(-(FV_ihalf).*dev.r0./(sol.params.physical_const.kBT)).*CT_ihalf+dev.krec.*(CT_ihalf-dev.CT0)-dev.kforEx.*(CT_ihalf);
%             figure
%             semilogy(CTfunction(end,:))
            djndx = - dndt + rg;%g - r.tot;
            djpdx = - dpdt + rg;% - r.tot;
            
            switch option
                case 0
                    % Integrate across the device to get delta fluxes at all positions
                    deltajn = cumtrapz(x, djndx, 2);
                    deltajp = cumtrapz(x, djpdx, 2);
                case 1
                    for ii = 1:length(t)
                        % Fluxes on half grid
                        djndx_ihalf(ii,:) = getvarihalf(djndx(ii,:));
                        djpdx_ihalf(ii,:) = getvarihalf(djpdx(ii,:));
                    end
                    x = getvarihalf(x);                   
                    deltajn = cumtrapz(x, djndx_ihalf, 2);
                    deltajp = cumtrapz(x, djpdx_ihalf, 2);
                case 2
                    deltajn = cumtrapz(x, djndx, 2);
                    deltajp = cumtrapz(x, djpdx, 2);
            end
            
            %% Currents from the boundaries
            switch par.Experiment_prop.BC
                case 2
                    jn_l = 0*n(:, 1);%;-par.sn_l*(n(:, 1) - par.nleft);
                    jp_l = 0*n(:, 1);%;-deltajp(:, end) + par.sp_r*(p(:, end) - par.pright);
                    
                    jn_r = 0*n(:, 1);%;deltajn(:, end) - par.sn_l*(n(:, 1) - par.nleft);
                    jp_r = 0*n(:, 1);%;par.sp_r*(p(:, end) - par.pright);
                case 3
                    jn_l = -par.External_prop.sn_l*(n(:, 1) - par.External_prop.nleft);
                    jp_l = -par.External_prop.sp_l*(p(:, 1) - par.External_prop.pleft);
                    
                    jn_r = par.External_prop.sn_r*(n(:, end) - par.External_prop.nright);
                    jp_r = par.External_prop.sp_r*(p(:, end) - par.External_prop.pright);
            end
            
            % Calculate total electron and hole currents from fluxes
            % Use the minority carrier flux as the boundary condition
%             if par.pleft >= par.nleft && par.nright >= par.pright
%                 % p-type left boundary, n-type right boundary
%                 j.n = jn_l + deltajn;
%                 j.p = jp_r + (deltajp - deltajp(:,end));
%             elseif par.nleft >= par.nright && par.pright >= par.nright
%                 % n-type left boundary, p-type right boundary
%                 j.n = jn_r + (deltajn-deltajn(:,end));
%                 j.p = jp_l + deltajp;
%             elseif par.pleft >= par.nleft && par.pright >= par.nright...
%                     || par.nleft >= par.pleft && par.nright >= par.pright
%                 % p-type both boundaries or n-type both boundaries
%                 j.n = jn_l + deltajn;
%                 j.p = jp_l + deltajp;
%             end
                j.n = jn_l + deltajn;
                j.p = jp_r +(deltajp - deltajp(:,end));

            % displacement flux
            j.disp = zeros(length(t), length(x));
            [FV, ~] = dfana.calcF(sol);
            for i = 1:length(t)
                FV_ihalf(i,:) = interp1(xmesh, FV(i,:), x);
            end
            % Property matrices
%             dev_ihalf = getdevihalf(par);
%             eppmat = repmat(dev_ihalf.epp, length(t), 1);
            
            for i = 1:length(x)
                j.disp(:,i) = dev.epp(:,i).*(gradient(FV_ihalf(:,i), t));%par.physical_const.epp0.*
            end
            
            J.n = j.n*-par.physical_const.e;
            J.p = j.p*par.physical_const.e;

            J.disp = j.disp*abs(par.physical_const.e);
            
            % Total current
            J.tot = J.n + J.p + J.disp;
        end
        
        function [g1, g2, g] = calcg(sol)
            par = sol.par;
            tmesh = sol.t;
            %% Generation function
            switch par.g1_fun_type
                case 'constant'
                    g1 = repmat(par.int1.*par.gx1, length(tmesh), 1);
                otherwise
                    g1_fun = fun_gen(par.g1_fun_type);
                    g1 = g1_fun(par.g1_fun_arg, tmesh')*par.gx1;
            end
            
            switch par.g2_fun_type
                case 'constant'
                    g2 = repmat(par.int2.*par.gx2, length(tmesh), 1);
                otherwise
                    g2_fun = fun_gen(par.g2_fun_type);
                    g2 = g2_fun(par.g2_fun_arg, tmesh')*par.gx2;
            end
            g = g1 + g2;
        end
        
        function rg = calcrg(sol)
            % obtain SOL components for easy referencing
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            rg.tot = dev.kdis.*CT-dev.kfor.*(n.*p);
        end
        
        function r = calcr_ihalf(sol)
            % obtain SOL components for easy referencing
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            for ii = 1:length(t)
                n_ihalf(ii,:) = getvarihalf(n(ii,:));
                p_ihalf(ii,:) = getvarihalf(p(ii,:));
            end
            x = getvarihalf(x);
            
            devihalf = getdevihalf(par);
            
            % Property matrices
            eppmat = repmat(devihalf.epp, length(t), 1);
            nimat = repmat(devihalf.ni, length(t), 1);
            Bmat = repmat(devihalf.B, length(t), 1);
            taunmat = repmat(devihalf.taun, length(t), 1);
            taupmat = repmat(devihalf.taup, length(t), 1);
            ntmat = repmat(devihalf.nt, length(t), 1);
            ptmat = repmat(devihalf.pt, length(t), 1);
            params.Layers{kk}.kdis*(u(3))- params.Layers{kk}.kfor*((u(1)*u(2)))
            % Recombination
            r.btb = Bmat.*(n_ihalf.*p_ihalf - nimat.^2);
            
            r.srh = ((n_ihalf.*p_ihalf - nimat.^2)./((taunmat.*(p_ihalf+ptmat)) + (taupmat.*(n_ihalf+ntmat))));
            
            r.tot = r.btb + r.srh;
        end
        
        function [jdd, Jdd, xout] = Jddxt(sol)
            % Calculates drift and diffusion currents at every point and all times -
            % NOTE: UNRELIABLE FOR TOTAL CURRENT as errors in the calculation of the
            % spatial gradients mean that the currents do not cancel properly
            option = 1;
            % obtain SOL components for easy referencing
            
            [u,t,xmesh,par,dev_i,n,p,a,c,V] = dfana.splitsol(sol);
            xhalfmesh = par.x_ihalf;
            dev_ihalf = par.dev_ihalf;
            
            switch option
                case 1
                    dev = dev_ihalf;
                    xout = xhalfmesh;
                case 2
                    dev = dev_i;
                    xout = xmesh;
                case 3
                    dev = dev_ihalf;
                    xout = xhalfmesh;
                case 4
                    dev = dev_ihalf;
                    xout = xhalfmesh;
            end
            % Property matrices
            eppmat = dev.epp;
            mue_mat = dev.mue;
            muh_mat = dev.muh;
            mu_cat = dev.mucat;
            mu_ani = dev.muani;
            gradEA_mat = dev.gradEA;
            gradIP_mat = dev.gradIP;
            gradNc_mat = dev.gradNc;
            gradNv_mat = dev.gradNv;
            Nc_mat = dev.Nc;
            Nv_mat = dev.Nv;
            
            for i = 1:length(t)
                
                switch option
                    case 1
                        [nloc(i,:),dndx(i,:)] = pdeval(0,xmesh,n(i,:),xhalfmesh);
                        [ploc(i,:),dpdx(i,:)] = pdeval(0,xmesh,p(i,:),xhalfmesh);
                        [aloc(i,:),dadx(i,:)] = pdeval(0,xmesh,a(i,:),xhalfmesh);
                        [cloc(i,:),dcdx(i,:)] = pdeval(0,xmesh,c(i,:),xhalfmesh);
                        [Vloc(i,:),dVdx(i,:)] = pdeval(0,xmesh,V(i,:),xhalfmesh);
                    case 2
                        [nloc(i,:),dndx(i,:)] = pdeval(0,xmesh,n(i,:),xmesh);
                        [ploc(i,:),dpdx(i,:)] = pdeval(0,xmesh,p(i,:),xmesh);
                        [aloc(i,:),dadx(i,:)] = pdeval(0,xmesh,a(i,:),xmesh);
                        [cloc(i,:),dcdx(i,:)] = pdeval(0,xmesh,c(i,:),xmesh);
                        [Vloc(i,:),dVdx(i,:)] = pdeval(0,xmesh,V(i,:),xmesh);
                    case 3
                        [nloc(i,:),~] = pdeval(0,xmesh,n(i,:),xhalfmesh);
                        [ploc(i,:),~] = pdeval(0,xmesh,p(i,:),xhalfmesh);
                        [aloc(i,:),~] = pdeval(0,xmesh,a(i,:),xhalfmesh);
                        [cloc(i,:),~] = pdeval(0,xmesh,c(i,:),xhalfmesh);
                        [Vloc(i,:),~] = pdeval(0,xmesh,V(i,:),xhalfmesh);
                        
                        dndx(i,:) = gradient(nloc(i,:), xhalfmesh);
                        dpdx(i,:) = gradient(ploc(i,:), xhalfmesh);
                        dadx(i,:) = gradient(aloc(i,:), xhalfmesh);
                        dcdx(i,:) = gradient(cloc(i,:), xhalfmesh);
                        dVdx(i,:) = gradient(Vloc(i,:), xhalfmesh);
                    case 4
                        for jj = 1:length(xmesh)-1
                            xnow = xmesh(jj) + 0.5*(xmesh(jj+1) - xmesh(jj));
                            [nloc(i,jj),dndx(i,jj)] = dfana.pdentrp(0,0,xmesh(jj),n(i,jj),xmesh(jj+1),n(i,jj+1),xnow);
                            [ploc(i,jj),dpdx(i,jj)] = dfana.pdentrp(0,0,xmesh(jj),p(i,jj),xmesh(jj+1),p(i,jj+1),xnow);
                            [aloc(i,jj),dadx(i,jj)] = dfana.pdentrp(0,0,xmesh(jj),a(i,jj),xmesh(jj+1),a(i,jj+1),xnow);
                            [cloc(i,jj),dcdx(i,jj)] = dfana.pdentrp(0,0,xmesh(jj),c(i,jj),xmesh(jj+1),c(i,jj+1),xnow);
                            [Vloc(i,jj),dVdx(i,jj)] = dfana.pdentrp(0,0,xmesh(jj),V(i,jj),xmesh(jj+1),V(i,jj+1),xnow);
                        end
                end
                
                % Diffusion coefficients
                if par.prob_distro_function == 'Fermi'
                    for jj = 1:length(x)
                        Dn(i,jj) = distro_fun.D(nloc(i,jj), dev.Dnfun(jj,:), dev.n_fd(jj,:));
                        Dp(i,jj) = distro_fun.D(ploc(i,jj), dev.Dpfun(jj,:), dev.p_fd(jj,:));
                    end
                end
            end
            
            if par.prob_distro_function == 'Boltz'
                Dn_mat = mue_mat*par.physical_const.kBT;
                Dp_mat = muh_mat*par.physical_const.kBT;
            end
            
            % Particle fluxes
            jdd.ndiff = par.mobset*-(-Dn_mat.*(dndx-((nloc./Nc_mat).*gradNc_mat)));
            jdd.ndrift = par.mobset*-(mue_mat.*nloc.*(dVdx-gradEA_mat));
            jdd.pdiff = par.mobset*(-Dp_mat.*(dpdx-((ploc./Nv_mat).*gradNv_mat)));
            jdd.pdrift = par.mobset*(muh_mat.*ploc.*(-dVdx+gradIP_mat));
            
            switch par.N_ionic_species
                case 0
                    jdd.cdiff = zeros(length(t), length(xout));
                    jdd.cdrift = zeros(length(t), length(xout));
                    jdd.adiff = zeros(length(t), length(xout));
                    jdd.adrift = zeros(length(t), length(xout));
                case 1
                    jdd.cdiff = par.mobseti*(-mu_cat.*par.physical_const.kBT.*dcdx);
                    jdd.cdrift = par.mobseti*(mu_cat.*cloc.*-dVdx);
                    jdd.adiff = zeros(length(t), length(xout));
                    jdd.adrift = zeros(length(t), length(xout));
                case 2
                    jdd.cdiff = par.mobseti*(-mu_cat.*par.physical_const.kBT.*dcdx);
                    jdd.cdrift = par.mobseti*(mu_cat.*cloc.*-dVdx);
                    jdd.adiff = par.mobseti*-(-mu_ani.*par.physical_const.kBT.*dadx);
                    jdd.adrift = par.mobseti*-(mu_ani.*aloc.*dVdx);
            end
            
            jdd.n = jdd.ndrift + jdd.ndiff;
            jdd.p = jdd.pdrift + jdd.pdiff;
            jdd.a = jdd.adrift + jdd.adiff;
            jdd.c = jdd.cdrift + jdd.cdiff;
            
            % Displacement current
            for i = 1:length(xout)
                j.disp(:,i) = par.epp0.*eppmat(:,i).*(gradient(-dVdx(:,i), t));
            end
            
            jdd.disp = j.disp;
            jdd.tot = jdd.n + jdd.p + jdd.a + jdd.c + jdd.disp;
            
            Jdd.ndrift = jdd.ndrift*par.e;
            Jdd.ndiff = jdd.ndiff*par.e;
            Jdd.pdrift = jdd.pdrift*par.e;
            Jdd.pdiff = jdd.pdiff*par.e;
            Jdd.adrift = jdd.adrift*par.e;
            Jdd.adiff = jdd.adiff*par.e;
            Jdd.cdrift = jdd.cdrift*par.e;
            Jdd.cdiff = jdd.cdiff*par.e;
            
            Jdd.n = par.e*jdd.n;
            Jdd.p = par.e*jdd.p;
            Jdd.a = par.e*jdd.a;
            Jdd.c = par.e*jdd.c;
            Jdd.disp = par.e*jdd.disp;
            Jdd.tot = par.e*jdd.tot;
        end
        
        function [FV, Frho] = calcF(sol)
            % Electric field caculation
            % FV = Field calculated from the gradient of the potential
            % Frho = Field calculated from integrated space charge density
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);         
            dev = dfana.develop(sol);
            rho = -n + p  - dev.NA + dev.ND;
            for i=1:length(t)
                FV(i,:) = -gradient(V(i, :), x);                      % Electric field calculated from V
            end
            Frho = cumtrapz(x, rho, 2)./(dev.epp) + FV(:,1);
        end
        
        function [FV, Frho] = calcF_ihalf(sol)
            % Electric field caculation
            % FV = Field calculated from the gradient of the potential
            % Frho = Field calculated from integrated space charge density
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            devi_ihalf = getdevihalf(par);
            
            x = getvarihalf(x);
            
            rho = dfana.calcrho_ihalf(sol);
            
            eppmat = repmat(devi_ihalf.epp, length(t), 1);
            
            for i=1:length(t)
                V_ihalf(i,:) = getvarihalf(V(i,:));
                FV(i,:) = -gradient(V_ihalf(i, :), x);                      % Electric field calculated from V
            end
            Frho = cumtrapz(x, rho, 2)./(eppmat.*par.epp0) + FV(:,1);
        end
        
        function rho = calcrho(sol)
            % Calculates the space charge density
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);    
            dev = dfana.develop(sol);
            % charge density
            rho = -n + p  - dev.NA + dev.ND;
        end
        
        function rho = calcrho_ihalf(sol)
            % Calculates the space charge density
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            for ii = 1:length(t)
                n_ihalf(ii,:) = getvarihalf(n(ii,:));
                p_ihalf(ii,:) = getvarihalf(p(ii,:));
                a_ihalf(ii,:) = getvarihalf(a(ii,:));
                c_ihalf(ii,:) = getvarihalf(c(ii,:));
            end
            x = getvarihalf(x);
            
            dev_ihalf = getdevihalf(par);
            
            NAmat = repmat(dev_ihalf.NA, length(t), 1);
            NDmat = repmat(dev_ihalf.ND, length(t), 1);
            
            % charge density
            rho = -n_ihalf + p_ihalf - a_ihalf + c_ihalf - NAmat + NDmat;
        end
        
        function Vapp = calcVapp(sol)
            par = sol.params;
            switch par.Experiment_prop.V_fun_type
                case 'constant'
                    Vapp = ones(1,length(sol.t))*par.Experiment_prop.Vapp;
                otherwise
                    Vapp_fun = fun_gen(par.Experiment_prop.V_fun_type);
                     time=sol.t;
                    Vapp = Vapp_fun(par.Experiment_prop.V_fun_arg,time');
            end
        end
        
        function stats = JVstats(JVsol)
            % A function to pull statistics from a JV sweep using DOJV
            % JVsol - a solution from DOJV
            if isfield(JVsol, 'ill')
                if isfield(JVsol.ill, 'f')
                    Vapp = dfana.calcVapp(JVsol.ill.f);
                    Vapp = Vapp';
                    J = dfana.calcJ(JVsol.ill.f);
                    try
                        stats.Jsc_f = interp1(Vapp, J.tot(:, end), 0);
                    catch
                        warning('No Jsc available- Vapp must pass through 0 to obtain Jsc')
                        stats.Jsc_f = 0;
                    end
                    
                    try
                        stats.Voc_f = interp1(J.tot(:, end), Vapp, 0);
                    catch
                        warning('No Voc available- try increasing applied voltage range')
                        stats.Voc_f = 0;
                    end
                    
                    if stats.Jsc_f ~= 0 && stats.Voc_f ~= 0
                        pow_f = J.tot(:,end).*Vapp;
                        stats.mpp_f = min(pow_f);
                        stats.mppV_f = Vapp(pow_f == stats.mpp_f);
                        stats.FF_f = stats.mpp_f/(stats.Jsc_f*stats.Voc_f);
                    end
                    
                    %% Hysteresis Index
                    A_f = abs(trapz(Vapp(Vapp >=0 & Vapp <= stats.Voc_f), J.tot(Vapp >= 0 & Vapp <= stats.Voc_f, end)));
                    
                else
                    stats.Jsc_f = nan;
                    stats.Voc_f = nan;
                    stats.mpp_f = nan;
                    stats.FF_f = nan;
                end
                
                if isfield(JVsol.ill, 'r')
                    Vapp = dfana.calcVapp(JVsol.ill.r);
                    Vapp = Vapp';
                    J = dfana.calcJ(JVsol.ill.r);
                    try
                        stats.Jsc_r = interp1(Vapp, J.tot(:, end), 0);
                    catch
                        warning('No Jsc available- Vapp must pass through 0 to obtain Jsc')
                        stats.Jsc_r = 0;
                    end
                    
                    try
                        stats.Voc_r = interp1(J.tot(:, end), Vapp, 0);
                    catch
                        warning('No Voc available- try increasing applied voltage range')
                        stats.Voc_r = 0;
                    end
                    
                    if stats.Jsc_r ~= 0 && stats.Voc_r ~= 0
                        pow_r = J.tot(:,end).*Vapp;
                        stats.mpp_r = min(pow_r);
                        stats.mppV_r = Vapp(pow_r == stats.mpp_r);
                        stats.FF_r = stats.mpp_r/(stats.Jsc_r*stats.Voc_r);
                    end
                    
                    %% Hysteresis Factor
                    A_r = abs(trapz(Vapp(Vapp >=0 & Vapp <= stats.Voc_r), J.tot(Vapp >= 0 & Vapp <= stats.Voc_r, end)));
                    
                    %% Sign to identify inverted hysteresis
                    if A_r >= A_f
                        B = 1;
                    elseif A_r < A_f
                        B = -1;
                    end
                    
                    stats.HF = B*abs((A_r - A_f)/A_r);
                    
                else
                    stats.Jsc_r = NaN;
                    stats.Voc_r = NaN;
                    stats.mpp_r = NaN;
                    stats.FF_r = NaN;
                    stats.HF = NaN;
                end
            else
            end
        end
        
        function value = PLt(sol)
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            Bmat = dev.B;
            value = trapz(x,(dev.B.*(n.*p-dev.ni.^2)),2);
        end
        
        function VQFL = calcVQFL(sol)
            % Get Quasi-Fermi Levels
            [~, ~, Efn, Efp] = dfana.QFLs(sol);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                if(par.Experiment_prop.symm==1)
                VQFL = Efn(:, (length(x)+1)/2) - Efp(:, 1);
                VQFL=VQFL-VQFL(1);
                else
                VQFL = Efn(:, end) - Efp(:, 1);
                end
%             end
        end
        
        function deltaV = deltaVt(sol, p1, p2)
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            % Calculates the electorstatic potential difference as a function of time
            % between two points P1 and P2
            deltaV = V(:,p1) - V(:,p2);
        end
        
        function sigma = calcsigma(sol)
            % calculates the integrated space charge density
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);    
            rho = dfana.calcrho(sol);
            sigma = trapz(x, rho, 2);
        end
        
        function sigma_ion = calcsigma_ion(sol)
            % calculates the integrated space charge density
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            rho_ion = c-a;
            sigma_ion = trapz(x, rho_ion, 2);
        end
        
        function Fion = calcFion(sol)
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            Ncatmat = repmat(dev.Ncat, length(t), 1);
            Nanimat = repmat(dev.Nani, length(t), 1);
            eppmat = repmat(dev.epp, length(t), 1);
            
            rhoion = c - Ncatmat - a + Nanimat;
            Fion = cumtrapz(x, rhoion, 2)./(eppmat*par.epp0);
        end
        
        function Vion = calcVion(sol)
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            Fion = dfana.calcFion(sol);
            Vion = -cumtrapz(x, Fion,2);
        end
        
        function [U,Ux] = pdentrp(singular,m,xL,uL,xR,uR,xout)
            % PDENTRP  Interpolation helper function for PDEPE.
            %   [U,UX] = PDENTRP(M,XL,UL,XR,UR,XOUT) uses solution values UL at XL and UR at XR
            %   for successive mesh points XL < XR to interpolate the solution values U and
            %   the partial derivative with respect to x, UX, at arguments XOUT(i) with
            %   XL <= XOUT(i) <= XR.  UL and UR are column vectors. Column i of the output
            %   arrays U, UX correspond to XOUT(i).
            %
            %   See also PDEPE, PDEVAL, PDEODES.
            
            %   Lawrence F. Shampine and Jacek Kierzenka
            %   Copyright 1984-2013 The MathWorks, Inc.
            %   $Revision: 1.5.4.4.54.1 $  $Date: 2013/09/27 03:10:22 $
            
            xout = xout(:)';
            nout = length(xout);
            
            U = uL(:,ones(1,nout));
            Ux = zeros(size(U));
            
            uRL = uR - uL;
            % Use singular interpolant on all subintervals.
            if singular
                U  = U + uRL*((xout .^ 2 - xL^2) / (xR^2 - xL^2));
                Ux =     uRL*(2*xout / (xR^2 - xL^2));
            else
                switch m
                    case 0
                        U  = U + uRL*( (xout - xL) / (xR - xL));
                        Ux =     uRL*(ones(1,nout) / (xR - xL));
                    case 1
                        U  = U + uRL*(log(xout/xL) / log(xR/xL));
                        Ux =     uRL*( (1 ./ xout) / log(xR/xL));
                    case 2
                        U  = U + uRL*((xR ./ xout) .* ((xout - xL)/(xR - xL)));
                        Ux =     uRL*((xR ./ xout) .* (xL ./ xout)/(xR - xL));
                end
            end
        end
    end
end