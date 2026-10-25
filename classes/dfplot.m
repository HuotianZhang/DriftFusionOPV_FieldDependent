
classdef dfplot
    % DRIFTFUSION Plotting class - contains methods for plotting
    %
    % List of available plots:
    % DFPLOT.JT = Currents as a function of time
    % DFPLOT.JX = Total currents as a function of position
    % DFPLOT.jx = Carrier fluxes as a function of position
    % DFPLOT.JV = Current-voltage curve using a solution from DOJV-
    % now outdated - preferrable to use DOCV and DFPLOT.JTOTVAPP
    % DFPLOT.JDDX = Drift and diffusion currents as a function of position
    % DFPLOT.VOCT = Open circuit voltage as a function of time
    % DFPLOT.PLT = Integrated radiative recombination rate as a function of
    % time
    % DFPLOT.VAPPT = Applied voltage as a function of time
    % DFPLOT.JVAPP = Current components as a function of the applied voltage at
    % position defined by XPOS
    % DFPLOT.JTOTVAPP = Total current as a function of the applied voltage at
    % position defined by XPOS
    % DFPLOT.LOGJVAPP = Current components as a function of the applied voltage
    % using log y-axis at position defined by XPOS
    % DFPLOT.XMESH = Plots the xmesh position vs point number
    % DFPLOT.VX = Electrostatic potential as a function of position
    % DFPLOT.NPX = Electron and hole densities as a function of position
    % DFPLOT.ACX = Anion and cation densities as a function of position
    % DFPLOT.GX = Generation rate as a function of position
    % DFPLOT.GXT = Generation rate as a function of position and time
    % DFPLOT.RX = Recombination rate components as a function of position
    % DFPLOT.JRECVAPP = Recomonbination components as a function of the applied
    % voltage
    % DFPLOT.FT = Electric field as a function of time
    % DFPLOT.SIGMAT = Integrated charge density in cm-2 as a function of time
    % DFPLOT.QT = Charge density in Coulombs cm-2 integrated between within the
    % range [X1, X2] as a function of time
    % DFPLOT.QVAPP = Charge density in Coulombs cm-2 integrated between within the
    % range [X1, X2] as a function of applied voltage
    % DFPLOT.RHOX = Volumetric charge density as a function of position
    % DFPLOT.DELTARHOX = Change in volumetric charge density as a function of position
    % DFPLOT.RHOXFXVX = Volumetric charge density, Electric field and Electrostatic potential
    % as a function of position- stacked plot
    % DFPLOT.RHOXVX = Volumetric charge density and Electrostatic potential as a function
    % of position- stacked plot
    % DFPLOT.ELX= Energy level diagram as a function of position
    % DFPLOT.ELXNPX = Energy level diagram, electron and hole densities
    % DFPLOT.ELXNPXACX = Energy level diagram, electron and hole densities,
    % and anion and cation densities, 3 panel, stacked
    % DFPLOT.VXACX = Electrostatic potential and anion and cation densities, 2
    % panel, stacked
    % DFPLOT.VIONXACX = Electrostatic potential due to ionic charge and anion and cation densities, 2
    % panel, stacked
    % DFPLOT.FIONT = Electric field due to the ionic charge as a function of
    % time
    
    % Plotting functions that are a function of position can accept a time
    % array as the second argument- the procedure will loop and plot the
    % solution at multiple times.
    % The third optional argument defines the x-range.
    % For plotting functions that are a function of time, the second argument
    % is generally the position at which the value is taken- see the comments
    % of individual methods below for further details
    
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
        
        function Jt(sol, xpos)
            % Currents as a function of time
            % SOL = solution structure
            % XPOS = the readout position
            t = sol.t;
            [J, j, xmesh] = dfana.calcJ(sol);
            ppos = getpointpos(xpos, xmesh);
            
            figure(2);
            plot(t, J.n(:, ppos),t, J.p(:, ppos),t, J.a(:, ppos),t, J.c(:, ppos), t, J.disp(:,ppos), t, J.tot(:, ppos));
            legend('Jn', 'Jp', 'Ja', 'Jc', 'Jdisp', 'Jtotal')
            xlabel('time [s]');
            ylabel('J [A cm^{-2}]');
            set(legend,'FontSize',16);
            set(legend,'EdgeColor',[1 1 1]);
        end
        
        function Jx(varargin)
            % Plots the current components
            % VARARGIN = [SOL, TARR, XRANGE]
            % SOL = Solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [XMIN, XMAX]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            %             [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            [J, j, x] = dfana.calcJ(sol);
            
            figure(3);
            dfplot.x2d(sol, x, {J.n, J.p, J.disp, J.tot},...
                {'Jn', 'Jp', 'Jdisp', 'Jtot'}, {'-','-','-','-','-','-'},...
                'Current density [Acm-2]', tarr, xrange, 0, 0);
        end
        
        function jx(varargin)
            % Plots the carrier fluxes
            % VARARGIN = [SOL, TARR, XRANGE]
            % SOL = Solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [XMIN, XMAX]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            [J, j, x] = dfana.calcJ(sol);
            
            figure(301);
            dfplot.x2d(sol, par.x_ihalf, {j.n, j.p,  j.disp},{'jn', 'jp', 'ja', 'jc', 'jdisp'},...
                {'-','-','-','-','-'}, 'Current density [Acm-2]', tarr, xrange, 0, 0);
        end
        
        function Jddx(varargin)
            % Drift and diffusion currents as a function of position
            % VARARGIN = [SOL, TARR, XRANGE]
            % SOL = Solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [XMIN, XMAX]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            [~, Jdd, x] = dfana.Jddxt(sol);
            
            figure(301);
            dfplot.x2d(sol, x, {Jdd.ndiff, Jdd.ndrift, Jdd.pdiff, Jdd.pdrift,...
                Jdd.adiff, Jdd.adrift, Jdd.cdiff, Jdd.cdrift},...
                {'Jn,diff', 'Jn,drift', 'Jp,diff', 'Jp,drift', 'Ja,diff', 'Ja,drift', 'Jc,diff', 'Jc,drift'},...
                {'.','-','.','-','.','-','.','-'},'Current density [Acm-2]', tarr, xrange, 0, 0);
        end
        
        function Voct(sol)
            Voc = dfana.calcVQFL(sol);
            figure(6)
            plot(sol.t, Voc)
            xlabel('Time [s]')
            ylabel('Voc [V]')
        end
        
        function Vappt(sol)
            % Applied voltage as a function of position
            Vapp = dfana.calcVapp(sol);
            
            figure(8)
            plot(sol.t, Vapp);
            xlabel('Time [s]')
            ylabel('Vapp [V]')
        end
        
        function PLt(sol)
            PL = dfana.PLt(sol);
            figure(7)
            plot(sol.t, PL)
            xlabel('Time [s]')
            ylabel('PL [cm-2s-1]')
        end
        function [Jsc,Voc,FF,JJ,VV]=JV_new(sol,figureplot,varargin)
            
            %this function calculates and plots the JV characthersitic from
            %the drift diffusion solution of runsolJV
            %Varargin{1} should be the Rshunt
            %Varargin{2} should be the name you want for the figure
            %Varargin{3} is the current: 'calcJ' (default, as published;
            %assumes no minority-carrier current at the contacts) or
            %'flux' (the drift-diffusion fluxes at the contact, including
            %minority carriers leaving through the opposite contact)
            method='calcJ';
            if numel(varargin)>=3 && ~isempty(varargin{3})
                method=validatestring(varargin{3},{'calcJ','flux'});
            end
            if isempty(varargin)
                Rshunt=1e15;
                plot_name='undefined';
                
            else
                Rshunt=varargin{1};
                if Rshunt==0
                    Rshunt=1e15;
                end
                plot_name='undefined';
                if numel(varargin)>=2
                    plot_name=varargin{2};
                end
            end
            if strcmp(method,'flux')
                J = dfana.calcJ_flux(sol);
            else
                J = dfana.calcJ(sol);
            end
            Vapp= dfana.calcVapp(sol);
            Vapp = Vapp(:);
            % Current at the contact plus the shunt current, used for the
            % plot, Jsc, Voc, FF and the returned curve alike
            Jtot = J.tot(:,end) + Vapp/Rshunt;
            % The first sample of a sweep restarted from an earlier solution
            % carries a spurious current from the time derivative in calcJ
            % (large at low mobility); drop it. The next sample is less than
            % 1e-5 V further, and Jsc is extrapolated back to 0 V.
            if numel(Jtot) > 2
                Jtot = Jtot(2:end);
                Vapp = Vapp(2:end);
            end
            
            if figureplot==1
                hold on
                plot(Vapp, Jtot*1000,'DisplayName',plot_name);
                
                ylim([-30, 10]);
                %ylim([-30e-3, 10e-3]);
                xlabel('Applied voltage [V]')
                ylabel('Current density [mA/cm^2]');
                hold off
            end
            Jsc=-interp1(Vapp,Jtot,0,'linear','extrap')*1e3;%in mAcm-2
            Voc=interp1(Jtot,Vapp,0);
            FF=max(-Vapp.*Jtot*1e3)/(Voc*Jsc);
            JJ=Jtot*1e3;
            VV=Vapp;
        end
        function JV(JV, option)
            % JV - a solution from doJV
            % OPTION - 1 = dark only, 2 = light only, 3 = dark & light
            % JV is a structure containing dark and illuminated JVs
            
            if option == 1 || option == 3
                J.dk.f = dfana.calcJ(JV.dk.f);
                Vapp.dk.f = dfana.calcVapp(JV.dk.f);
                J.dk.r = dfana.calcJ(JV.dk.r);
                Vapp.dk.r = dfana.calcVapp(JV.dk.r);
                
                figure(4)
                plot(Vapp.dk.f, J.dk.f.tot(:,end), '--', Vapp.dk.r, J.dk.r.tot(:,end));
                hold on
            end
            
            if option == 2 || option == 3
                
                J.ill.f = dfana.calcJ(JV.ill.f);
                Vapp.ill.f = dfana.calcVapp(JV.ill.f);
                J.ill.r = dfana.calcJ(JV.ill.r);
                Vapp.ill.r = dfana.calcVapp(JV.ill.r);
                
                figure(4)
                plot(Vapp.ill.f, J.ill.f.tot(:,end),'--')%, 'Color', [0, 0.4470, 0.7410]);
                hold on
                plot(Vapp.ill.r, J.ill.r.tot(:,end));%,'Color', [0, 0.4470, 0.7410]);
            end
            
            figure(4)
            %ylim([-30e-3, 10e-3]);
            xlabel('Applied voltage [V]')
            ylabel('Current density [Acm-2]');
            hold off
        end
        
        function JVapp(sol, xpos)
            % Obtain point position from x position
            xmesh = sol.x;
            ppos = getpointpos(xpos, xmesh);
            
            J = dfana.calcJ(sol);
            Vapp = dfana.calcVapp(sol);
            
            figure(9)
            plot(Vapp, J.n(:, ppos),Vapp, J.p(:, ppos),Vapp, J.a(:, ppos),Vapp, J.disp(:,ppos), Vapp, J.tot(:, ppos));
            legend('Jn', 'Jp', 'Ja', 'Jdisp', 'Jtotal')
            xlabel('Applied Voltage, Vapp [V]');
            ylabel('Current Density, J [A cm^{-2}]');
            set(legend,'FontSize',16);
            set(legend,'EdgeColor',[1 1 1]);
        end
        
        function JtotVapp(sol, xpos)
            % Obtain point position from x position
            xmesh = sol.x;
            ppos = getpointpos(xpos, xmesh);
            
            J = dfana.calcJ(sol);
            Vapp = dfana.calcVapp(sol);
            
            figure(91)
            plot(Vapp, J.tot(:, ppos));
            xlabel('Applied Voltage, Vapp [V]');
            ylabel('Current Density, J [A cm^{-2}]');
            set(legend,'FontSize',16);
            set(legend,'EdgeColor',[1 1 1]);
        end
        
        
        function logJVapp(sol, xpos)
            % plot the log of the mod J
            
            xmesh = sol.x;
            ppos = getpointpos(xpos, xmesh);
            
            J = dfana.calcJ(sol);
            Vapp = dfana.calcVapp(sol);
            
            figure(10)
            semilogy(Vapp, abs(J.tot(:,ppos)), Vapp, abs(J.n(:,ppos)), Vapp, abs(J.p(:,ppos)), Vapp, abs(J.a(:,ppos)),Vapp, abs(J.c(:,ppos)), Vapp, abs(J.disp(:,ppos)));
            xlabel('Vapp [V]');
            ylabel('|J| [A cm^{-2}]');
            legend('Jtot', 'Jn', 'Jp', 'Ja', 'Jc', 'Jdisp')
            set(legend,'FontSize',16);
            set(legend,'EdgeColor',[1 1 1]);
        end
        
        function logJVapp3D(sol, xpos, ylogon)
            
            xmesh = sol.x;
            ppos = getpointpos(xpos, xmesh);
            
            t = sol.t;
            J = dfana.calcJ(sol);
            Vapp = dfana.calcVapp(sol)';
            Jtot=J.tot(:, ppos);
            
            figure(11)
            surface('XData', [Vapp Vapp],             ... % N.B.  XYZC Data must have at least 2 cols
                'YData', [abs(Jtot) abs(Jtot)],             ...
                'ZData', [t' t'], ...
                'CData', [t' t'],             ...
                'FaceColor', 'none',        ...
                'EdgeColor', 'interp',      ...
                'Marker', 'none','LineWidth',1);
            s1 = gca;
            xlabel('Vapp [V]');
            ylabel('|J| [A cm^{-2}]');
            
            if ylogon
                set(s1,'YScale','log');
            else
                set(s1,'YScale','linear');
            end
            hold off
        end
        
        function xmesh(sol)
            figure(11)
            plot(sol.x)
            xlabel('Position [cm]')
            ylabel('Point')
        end
        
        function Vx(varargin)
            % Electrostatic potential as a function of position
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            figure(12);
            dfplot.x2d(sol, x, {V},{'V'},{'-'},'Electrostatic potential [V]', tarr, xrange, 0, 0);
        end
        
        function npx(varargin)
            % Carrier densities as a function of position
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            figure(13);
            dfplot.x2d(sol, x, {n, p}, {'n', 'p'}, {'-','-'},...
                'Carrier density [cm-3]', tarr, xrange, 0, 1)
        end
        
        function acx(varargin)
            % Ionic carrier densities as a function of position
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            figure(14)
            dfplot.x2d(sol, x, {a,c},{'anion','cation'}, {'-','-'},...
                'Ionic carrier density [cm-3]', tarr, xrange, 0, 0);
        end
        
        function gx(varargin)
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            [g1, g2, g] = dfana.calcg(sol);
            
            figure(15)
            dfplot.x2d(sol, par.x_ihalf, {g1, g2, g}, {'g1', 'g2', 'g total'},...
                {'-','-','-'}, 'Generation rate [cm-3s-1]', tarr, xrange, 0, 0);
        end
        
        function gxt(sol)
            % Carrier densities as a function of position
            par = sol.par;
            t = sol.t;
            [~, ~, g] = dfana.calcg(sol);
            xnm = par.x_ihalf*1e7;
            
            figure(16)
            surf(xnm, sol.t, g)
            xlabel('Position [cm]')
            ylabel('Time [s]')
            zlabel('Generation rate [cm^{-3}s^{-1}]')
        end
        
        function rx(varargin)
            % Recombination rates as a function of position
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            r = dfana.calcr(sol);
            
            figure(17)
            dfplot.x2d(sol, x, {r.btb, r.srh, r.tot},{'rbtb', 'rsrh', 'rtot'},...
                {'-','-','-'}, 'Recombination rate [cm-3s-1]', tarr, xrange, 0, 0);
        end
        
        function JrecVapp(JV, option)
            % Plots recombination currents for JV
            
            % JV - a solution from doJV
            % OPTION - 1 = dark only, 2 = light only, 3 = dark & light
            % JV is a structure containing dark and illuminated JVs
            
            if option == 1 || option == 3
                J.dk.f = dfana.calcJ(JV.dk.f);
                Vapp.dk.f = dfana.calcVapp(JV.dk.f);
                J.dk.r = dfana.calcJ(JV.dk.r);
                Vapp.dk.r = dfana.calcVapp(JV.dk.r);
                
                figure(13)
                plot(Vapp.dk.f, J.dk.f.tot(:,end), '--', Vapp.dk.r, J.dk.r.tot(:,end));
                hold on
            end
            
            if option == 2 || option == 3
                solf = JV.ill.f;
                solr = JV.ill.r;
                par = solf.par;
                pcum0 = par.pcum0;
                
                J.ill.f = dfana.calcJ(JV.ill.f);
                Vapp.ill.f = dfana.calcVapp(JV.ill.f);
                J.ill.r = dfana.calcJ(JV.ill.r);
                Vapp.ill.r = dfana.calcVapp(JV.ill.r);
                
                r_f = dfana.calcr(JV.ill.f);
                Jrec_btb_f = JV.ill.f.par.e*trapz(JV.ill.f.x, r_f.btb, 2);
                Jrec_srhint_f = JV.ill.f.par.e*trapz(JV.ill.f.x(pcum0(2)+1:pcum0(3)), r_f.srh(:,pcum0(2)+1:pcum0(3)), 2)...
                    +JV.ill.f.par.e*trapz(JV.ill.f.x(pcum0(4)+1:pcum0(5)), r_f.srh(:,pcum0(4)+1:pcum0(5)), 2);
                Jrec_srhbulk_f = JV.ill.f.par.e*trapz(JV.ill.f.x(pcum0(3)+1:pcum0(4)), r_f.srh(:,pcum0(3)+1:pcum0(4)), 2);
                Jrec_tot_f = JV.ill.f.par.e*trapz(JV.ill.f.x, r_f.tot, 2);
                
                r_rev = dfana.calcr(JV.ill.r);
                Jrec_btb_r = JV.ill.f.par.e*trapz(JV.ill.r.x, r_rev.btb, 2);
                Jrec_srhint_r = JV.ill.r.par.e*trapz(JV.ill.r.x(pcum0(2)+1:pcum0(3)), r_rev.srh(:,pcum0(2)+1:pcum0(3)), 2)...
                    +JV.ill.r.par.e*trapz(JV.ill.r.x(pcum0(4)+1:pcum0(5)), r_rev.srh(:,pcum0(4)+1:pcum0(5)), 2);
                Jrec_srhbulk_r = JV.ill.r.par.e*trapz(JV.ill.r.x(pcum0(3)+1:pcum0(4)), r_rev.srh(:,pcum0(3)+1:pcum0(4)), 2);
                Jrec_tot_r = JV.ill.r.par.e*trapz(JV.ill.r.x, r_rev.tot, 2);
                
                cc=lines(4);
                
                figure(13)
                plot(Vapp.ill.f, J.ill.f.tot(:,end),'--', 'Color', cc(1,:));
                hold on
                plot(Vapp.ill.r, J.ill.r.tot(:,end), 'Color', cc(1,:));
                % Recombination currents
                plot(Vapp.ill.f, Jrec_btb_f,'--','Color', cc(2,:));
                plot(Vapp.ill.r, Jrec_btb_r,'Color', cc(2,:));
                plot(Vapp.ill.f, Jrec_srhint_f,'--','Color', cc(3,:));
                plot(Vapp.ill.r, Jrec_srhint_r, 'Color', cc(3,:));
                plot(Vapp.ill.f, Jrec_srhbulk_f,'--','Color', cc(4,:));
                plot(Vapp.ill.r, Jrec_srhbulk_r, 'Color', cc(4,:));
            end
            
            figure(13)
            ylim([-30e-3, 10e-3]);
            xlabel('Applied voltage [V]')
            ylabel('Current density [Acm-2]');
            hold off
            legend('Illumated for', 'Illumated rev','Jrec,btb for','Jrec,btb rev'...
                ,'Jrec,srh-int for','Jrec,srh-int rev','Jrec,srh-bulk for','Jrec,srh-bulk rev')
        end
        
        function Ft(sol, xpos)
            % Absolute field strength F as a function of time at point
            % position XPOS
            xmesh = sol.x;
            ppos = getpointpos(xpos, xmesh);
            
            F = dfana.calcF(sol);
            
            figure(14)
            plot(sol.t, F(:,ppos))
            xlabel('Time [s]')
            ylabel(['Electric Field at pos x = ', num2str(round(xpos*1e7)), 'nm [Vcm-1]'])
        end
        
        function sigmat(sol)
            % Plot the integrated space charge density [cm-2] as a function of time
            sigma = dfana.calcsigma(sol);
            t = sol.t;
            
            figure(15)
            plot(t, sigma)
            xlabel('Time [s]')
            ylabel('sigma [C cm-2]')
        end
        
        function Qt(sol, x1, x2)
            % Plot the integrated space charge density in Coulombs [Ccm-2] as a function of time
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            p1 = find(x<=x1);
            p1 = p1(end);
            p2 = find(x<=x2);
            p2 = p2(end);
            
            sigma = dfana.calcsigma(sol);
            Q = par.e*sigma(:, x1:x2);
            
            figure(17)
            plot(t, Q)
            xlabel('Time [s]')
            ylabel('Charge [C cm-2]')
            xlim([t(1), t(end)])
        end
        function CTExT(sol,layernum)
            %             close all
            
            % Plot the integrated space charge density in Coulombs [Ccm-2] as a function of time
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            tstart=sol.params.pulse_properties.tstart;
            tpulse=sol.params.pulse_properties.pulselen;
            XR=sol.params.Layers{layernum}.XR;
            XL=sol.params.Layers{layernum}.XL;
            CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
            Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
            nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2);
            figure(16)
            
            subplot(1,2,1)
            loglog(t, (CTsum-CTsum(1)))%/max((Exsum-Exsum(1))))
            hold on
            loglog(t, (Exsum-Exsum(1)))%/max((Exsum-Exsum(1))))
                        semilogx(t, (nsum-nsum(1)))%/max((Exsum-Exsum(1))))
            
            xlabel('Time [s]')
            ylabel(' Excited state density [cm-2]')
            xlim([max(t(1),1e-9), t(end)])
            legend("CT","Ex","electron")
            %             figure(17)
            subplot(1,2,2)
            
            loglog(t-tstart, (CTsum-CTsum(1))/max((CTsum-CTsum(1))))
            hold on
            loglog(t-tstart,(Exsum-Exsum(1))/max((Exsum-Exsum(1))))
                                    semilogx(t-tstart, (nsum-nsum(1))/max((nsum-nsum(end))))
            xlabel('Time [s]')
            ylabel(' normalisedExcited state density [cm-2]')
            xlim([max(t(1),1e-9), t(end)])
            legend("CT","Ex","electron")
            ylim([1e-3,1.1])
            %
            %             xlabel('Time [s]')
            %             ylabel('Normalised Excited state density [cm-2]')
            %             xlim([t(1), t(end)])
            %             legend("CT","Ex","electron")
            %             figure(18)
            %             semilogx(t-tstart-tpulse, (CTsum-CTsum(1))/max((Exsum-Exsum(1))))
            %             hold on
            %             semilogx(t-tstart-tpulse,(Exsum-Exsum(1))/max((Exsum-Exsum(1))))
            %             semilogx(t-tstart-tpulse, (nsum-nsum(1))/max((Exsum-Exsum(1))))
            %
            %             xlabel('Time [s]')
            %             ylabel('Normalised Excited state density [cm-2]')
            %             xlim([t(1), t(end)])
            %             legend("CT","Ex","electron")
        end
        function QVapp(sol, x1, x2)
            % Integrated charge density as a function of applied voltage
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            p1 = find(x<=x1);
            p1 = p1(end);
            p2 = find(x<=x2);
            p2 = p2(end);
            
            sigma = dfana.calcsigma(sol);
            Vapp = dfana.calcVapp(sol);
            Q = par.e*sigma(:, x1:x2);
            
            figure(17)
            plot(Vapp, Q)
            xlabel('Vapp [V]')
            ylabel('Charge [C cm-2]')
            xlim([Vapp(1), Vapp(end)])
        end
        
        function rhox(varargin)
            % Volumetric charge density (rho) as a funciton of position
            % A time array can be used as a second input argument
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            rho = dfana.calcrho(sol);
            
            figure(19)
            dfplot.x2d(sol, x, {rho},{'\rho'},{'-'},'Charge density [cm-3]', tarr, xrange, 0, 0);
        end
        
        function deltarhox(varargin)
            % The change in volumetric charge density (rho) as a funciton of position
            % A time array can be used as a second input argument
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            rho = dfana.calcrho(sol);
            deltarho = rho - rho(1,:);
            
            figure(20)
            dfplot.x2d(sol, x, {deltarho},{'\Delta \rho'},{'-'},'Delta charge density [cm-3]', tarr, xrange, 0, 0);
        end
        
        function rhoxFxVx(varargin)
            % Three panel figure:
            % Volumetric charge density (rho), Field and potential as a funciton of position
            % A time array can be used as a second input argument
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            
            rho = dfana.calcrho(sol);
            F = dfana.calcF(sol);
            
            figure(21)
            subplot(3, 1, 1)
            dfplot.x2d(sol, x, {rho},{'\rho'},{'-'}, 'Charge density [cm-3]', tarr, xrange, 0, 0);
            
            subplot(3, 1, 2)
            dfplot.x2d(sol, x, {F},{'F'},{'-'},'Electric field [Vcm-1]', tarr, xrange, 0, 0);
            
            subplot(3, 1, 3)
            dfplot.x2d(sol, x, {V},{'V'},{'-'},'Electrostatic potential [V]', tarr, xrange, 0, 0);
        end
        
        function rhoxVx(varargin)
            % Three panel figure:
            % Volumetric charge density (rho), Field and potential as a funciton of position
            % A time array can be used as a second input argument
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            
            rho = dfana.calcrho(sol);
            
            figure(211)
            subplot(2, 1, 1)
            dfplot.x2d(sol, x, {rho},{'\rho'},{'-'}, 'Charge density [cm-3]', tarr, xrange, 0, 0);
            
            subplot(2, 1, 2)
            dfplot.x2d(sol, x, {-V},{'V'},{'-'},'-Electrostatic potential [V]', tarr, xrange, 0, 0);
        end
        
        function ELx(varargin)
            % Energy Level diagram, and charge densities plotter
            % SOL = the solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [xmin, xmax]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            x=sol.x;
            [Ecb, Evb, Efn, Efp] = dfana.QFLs(sol);
            
            figure(22);
            dfplot.x2d(sol, x, {Efn, Efp, Ecb, Evb}, {'E_{fn}', 'E_{fp}', 'CB', 'VB'},...
                {'--', '--', '-', '-'}, 'Energy [eV]', tarr, xrange, 0, 0)
        end
        
        function ELnpx(varargin)
            % Energy Level diagram, and charge densities plotter
            % SOL = the solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [xmin, xmax]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            [Ecb, Evb, Efn, Efp] = dfana.QFLs(sol);
            
            figure(23)
            subplot(2,1,1);
            dfplot.x2d(sol, x, {Efn, Efp, Ecb, Evb}, {'E_{fn}', 'E_{fp}', 'CB', 'VB'},...
                {'--', '--', '-', '-'}, 'Energy [eV]', tarr, xrange, 0, 0);
            
            subplot(2,1,2);
            dfplot.x2d(sol, x, {n, p}, {'n', 'p'}, {'-', '-'}, 'El carrier density [cm-3]', tarr, xrange, 0, 1);
        end
        
        function ELxnpxacx(varargin)
            % Energy Level diagram, and charge densities plotter
            % SOL = the solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [xmin, xmax]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            [Ecb, Evb, Efn, Efp] = dfana.QFLs(sol);
            
            figure(1);
            subplot(3,1,1);
            dfplot.x2d(sol, x, {Efn, Efp, Ecb, Evb}, {'E_{fn}', 'E_{fp}', 'CB', 'VB'}, {'--', '--', '-', '-'}, 'Energy [eV]', tarr, xrange, 0, 0)
            
            subplot(3,1,2);
            dfplot.x2d(sol, x, {n, p}, {'n', 'p'}, {'-', '-'}, 'El carrier density [cm-3]', tarr, xrange, 0, 1)
            
            figure(1);
            subplot(3,1,3);
            dfplot.x2d(sol, x, {a, c}, {'a', 'c'}, {'-', '-'}, 'Ionic carrier density [cm-3]', tarr, xrange, 0, 0)
        end
        
        function ELxnpCTEx(varargin)
            % Energy Level diagram, and charge densities plotter
            % SOL = the solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [xmin, xmax]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            [Ecb, Evb, Efn, Efp] = dfana.QFLs(sol);
            
            figure
            subplot(3,1,1);
            dfplot.x2d(sol, x, {Efn, Efp, Ecb, Evb}, {'E_{fn}', 'E_{fp}', 'CB', 'VB'},...
                {'--', '--', '-', '-'}, 'Energy [eV]', tarr, xrange, 0, 0);
            
            subplot(3,1,2);
            dfplot.x2d(sol, x, {n, p}, {'n', 'p'}, {'-', '-'}, 'El carrier density [cm-3]', tarr, xrange, 0, 1);
            
            subplot(3,1,3);
            dfplot.x2d(sol, x, {CT, Ex}, {'CT', 'Ex'}, {'-', '-'}, 'Excited state density [cm-3]', tarr, xrange, 0, 1)
        end
        function Electrondistrbution(DV,varargin)
            % Energy Level diagram, and charge densities plotter
            % SOL = the solution structure
            % TARR = An array containing the times that you wish to plot
            % XRANGE = 2 element array with [xmin, xmax]
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            [Ecb, Evb, Efn, Efp] = dfana.QFLs(sol);
            
            figure

            
            subplot(3,1,1);
            dfplot.x2d(sol, x, {n}, {'n', 'p'}, {'-', '-'}, 'El carrier density [cm-3]', tarr, xrange, 0, 1);
            ylim([1e12,1e19])
            subplot(3,1,2);
            dfplot.x2d(sol, x, {CT}, {'CT', 'Ex'}, {'-', '-'}, 'Excited state density [cm-3]', tarr, xrange, 0, 1);
                        XR=par.Layers{2}.XR;
            XL=par.Layers{2}.XL;
             CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
            Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
                       
            Luminescence=DV.Prec.params.Ex.results.krE.*Exsum+...
                DV.Prec.params.CT.results.krE.*CTsum;
            [peakint,peakpos]=max(Luminescence');
  subplot(3,1,3);
            loglog(t, peakint/max(peakint),'LineWidth',2)%/max((Exsum-Exsum(1))))
            
            
            
            hold on
            lg=legend();
            Vstep=sol.params.Experiment_prop.V_fun_arg(2)-sol.params.Experiment_prop.V_fun_arg(1);
            lg.String{end}=" Electroluminescence intensity "+num2str(Vstep)+" V";
            
            xlabel('Time [s]')
            ylabel('peak intensity [a.u]')
            ylim([1e-2,1.1])
            xlim([min(t(1),1e-7),max(t)])
        end
        function Vxacx(varargin)
            % Potential and ionic charges as a function of position
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            
            figure(24)
            subplot(2,1,1);
            dfplot.x2d(sol, x, {V}, {'V'},...
                {'-'}, 'Electro. potential [V]', tarr, xrange, 0, 0);
            
            subplot(2,1,2);
            dfplot.x2d(sol, x, {a, c}, {'a', 'c'},...
                {'-', '-'}, 'Ionic carrier density [cm-3]', tarr, xrange , 0, 0);
        end
        
        function Vionxacx(varargin)
            % Electrostatic potential as a function of position
            [sol, tarr, pointtype, xrange] = dfplot.sortarg(varargin);
            [u,t,x,par,dev,n,p,a,c,V] = dfana.splitsol(sol);
            Vion = dfana.calcVion(sol);
            Vel = V - Vion;
            
            figure(25)
            subplot(2,1,1);
            dfplot.x2d(sol, x, {V, Vion, Vel}, {'V', 'Vion', 'Vel'},...
                {'--', '.', '-'}, 'Electro. potential [V]', tarr, xrange, 0, 0);
            
            subplot(2,1,2);
            dfplot.x2d(sol, x, {a, c}, {'a', 'c'},...
                {'-', '-'}, 'Ionic carrier density [cm-3]', tarr, xrange , 0, 0);
        end
        
        function Fiont(sol, xpos)
            % Field contribution from ionic charge FION as a function of time at position XPOS
            xmesh = sol.x;
            ppos = getpointpos(xpos, xmesh);
            
            Fion = dfana.calcFion(sol);
            t = sol.t;
            
            figure(26)
            plot(t, Fion(:,ppos))
            xlabel('Time')
            ylabel('Ion field [Vcm-1]')
        end
        
        function colourblocks(sol, yrange)
            par = sol.params;
            dcum0 = par.Xgrid_properties*1e7;   % Convert to nm
            
            for i =1:length(dcum0)-1
                v = [dcum0(i) yrange(2); dcum0(i+1) yrange(2); dcum0(i+1) yrange(1); dcum0(i) yrange(1)];   % vertices position
                f = [1 2 3 4];    % Faces
                if length(par.layer_colour) == length(dcum0)-1
                    j = i;
                else
                    j = i - ((length(par.layer_colour)-1)*floor(i/length(par.layer_colour)));
                end
                colour = par.layer_colour(1,:);
                patch('Faces',f,'Vertices',v,'FaceColor',colour, 'EdgeColor','none');%,'HandleVisibility','off')
            end
            
            hold on
        end
        
        function Electroluminescence(DV,layernum,Voltage,Currentdensity)
            %set Voltage=0 and Currentdensity to the desired value to get
            %the el at fixed current,
            %or Currendensity=0 and voltage to the desired value
            %voltage in Volt and Currentdensity in mA/cm^2
            CTsum=0;
            for sol = DV.sol_JV
                
                if sol.params.light_properties.Int<1e-5
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    J = dfana.calcJ(sol);
                    Current_density=J.tot(:,end)*1e3;
                    Vapp = dfana.calcVapp(sol);
                    if Currentdensity==0
                    if max(Vapp>Voltage*0.9 & Vapp<Voltage*1.1)
                        CTsum=mean(trapz(x(x>XL & x<XR), CT(Vapp>Voltage*0.9 & Vapp<Voltage*1.1 ,x>XL & x<XR), 2));
                        Exsum=mean(trapz(x(x>XL & x<XR), Ex(Vapp>Voltage*0.9 & Vapp<Voltage*1.1 ,x>XL & x<XR), 2));
                    else
                        disp("the JV did not run until the desired voltage")
                    end
                    else
                        if max(Current_density>Currentdensity*0.9 & Current_density<Currentdensity*1.1)
                            CTsum=mean(trapz(x(x>XL & x<XR), CT(Current_density>Currentdensity*0.9 & Current_density<Currentdensity*1.1,x>XL & x<XR), 2));
                            Exsum=mean(trapz(x(x>XL & x<XR), Ex(Current_density>Currentdensity*0.9 & Current_density<Currentdensity*1.1,x>XL & x<XR), 2));
                        else
                            disp("the JV did not run until the desired current density")
                        end
                    end
                    
                end
            end
            if CTsum==0
                disp("the dark JV does not exist")
            else
                krE=DV.Prec.params.CT.results.krE*CTsum+DV.Prec.params.Ex.results.krE*Exsum;
                figure
                semilogy(DV.Prec.const.Edistribution,krE)
                hold on
                semilogy(DV.Prec.const.Edistribution,DV.Prec.params.CT.results.krE*CTsum)
                semilogy(DV.Prec.const.Edistribution,DV.Prec.params.Ex.results.krE*Exsum)
                
                xlabel('Energy [eV]')
                ylabel('Electroluminescence Emission  [a.u]')
                ylim([max(krE)*1e-3, max(krE)])
                legend("ToT","From CT","FromEx")
                if Currentdensity==0
                    title(['electroluminescence at ' num2str(Voltage) ' V'])
                else
                    title(['electroluminescence at ' num2str(Currentdensity) ' mAcm^-^2'])

                end
            end
        end
        function [X,Y]=Electroluminescence_multi(DV,layernum,Voltage,Currentdensity,label,varargin)
            %set Voltage=0 and Currentdensity to the desired value to get
            %the el at fixed current,
            %or Currendensity=0 and voltage to the desired value
            %voltage in Volt and Currentdensity in mA/cm^2
            %Rshunt 
            if isempty(varargin)
                Rshunt=1e15;
            else
                Rshunt=varargin{1};
            if Rshunt==0
                Rshunt=1e15;
            end
            end
            CTsum=0;
            for sol = DV.sol_JV
                
                if sol.params.light_properties.Int<1e-5
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    J = dfana.calcJ(sol);
                    Current_density=J.tot(:,end)*1e3;
                    Vapp = dfana.calcVapp(sol);
                    Current_density=Current_density+Vapp/Rshunt*1e3;%include shunt
                    if Currentdensity==0
                    if max(Vapp>Voltage*0.9 & Vapp<Voltage*1.1)
                        CTsum=mean(trapz(x(x>XL & x<XR), CT(Vapp>Voltage*0.9 & Vapp<Voltage*1.1 ,x>XL & x<XR), 2));
                        Exsum=mean(trapz(x(x>XL & x<XR), Ex(Vapp>Voltage*0.9 & Vapp<Voltage*1.1 ,x>XL & x<XR), 2));
                    else
                        disp("the JV did not run until the desired voltage")
                    end
                    else
                        if max(Current_density>Currentdensity )
                            try
                                CTsum=mean(trapz(x(x>XL & x<XR), CT(Current_density>Currentdensity*0.9 & Current_density<Currentdensity*1.1,x>XL & x<XR), 2));
                                Exsum=mean(trapz(x(x>XL & x<XR), Ex(Current_density>Currentdensity*0.9 & Current_density<Currentdensity*1.1,x>XL & x<XR), 2));
                                if isnan(CTsum)
                                     error('could not find the right current density')
                                end
                            catch ME
                                disp( ME.message+"\n using an interpolation method ")
                                CTsum_h=mean(trapz(x(x>XL & x<XR), CT(find(Current_density>Currentdensity,1),x>XL & x<XR), 2));
                                Exsum_h=mean(trapz(x(x>XL & x<XR), Ex(find(Current_density>Currentdensity,1),x>XL & x<XR), 2));
                                CTsum_l=mean(trapz(x(x>XL & x<XR), CT(find(Current_density<Currentdensity,end),x>XL & x<XR), 2));
                                Exsum_l=mean(trapz(x(x>XL & x<XR), Ex(find(Current_density<Currentdensity,end),x>XL & x<XR), 2));
                                CTsum=(CTsum_h+CTsum_l)/2;
                                Exsum=(Exsum_l+Exsum_h)/2;
                            end 
                        else
                            disp("the JV did not run until the desired current density")
                            
                        end
                    end
                    
                end
            end
            if CTsum==0
                disp("the dark JV does not exist")
            else
                krE=DV.Prec.params.CT.results.krE*CTsum+DV.Prec.params.Ex.results.krE*Exsum;
                semilogy(DV.Prec.const.Edistribution,krE)
                
                xlabel('Energy [eV]')
                ylabel('Electroluminescence Emission  [a.u]')
                ylim([max(krE)*1e-1, max(krE)])
                lg=legend;
                lg.String{end}=label;
                X=DV.Prec.const.Edistribution;
                Y=krE;
                if Currentdensity==0
                    title(['electroluminescence at ' num2str(Voltage) ' V'])
                else
                    title(['electroluminescence at ' num2str(Currentdensity) ' mAcm^-^2'])
                    
                end
            end
        end
        function Electroluminescence_VorJ(DV,layernum,Voltage,Currentdensity,label)
            %set Voltage=0 to plot as a function of current
            %or Currendensity=0 to plot as a function of voltage
            CTsum=0;
            for sol = DV.sol_JV
                
                if sol.params.light_properties.Int<1e-5
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    J = dfana.calcJ(sol);
                    Current_density=J.tot(:,end)*1e3;
                    Vapp = dfana.calcVapp(sol);
                    CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2)/(XR-XL);
                    Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2)/(XR-XL);

                    
                end
            end
            if CTsum==0
                disp("the dark JV does not exist")
            else
                krE=DV.Prec.params.CT.results.krTot*CTsum+DV.Prec.params.Ex.results.krTot*Exsum;
                subplot(2,1,1)
                if Currentdensity==0
                semilogy(Vapp,krE)
                
                xlabel('applied voltage [V]')
                else
                    loglog(Current_density,krE)
                    
                    xlabel('current density  [mA cm^-^2]')
                end
                ylabel('Electroluminescence Emission  [a.u]')
                ylim([max(krE)*1e-3, max(krE)])
                lg=legend;
                lg.String{end}=label;
                                subplot(2,1,2)
                if Currentdensity==0
                    hold off
                semilogy(Vapp,CTsum)
                hold on
                semilogy(Vapp,Exsum)
                xlabel('applied voltage [V]')
                else
                    hold off
                    loglog(Current_density,CTsum)
                                    hold on
                loglog(Current_density,Exsum)
                    xlabel('current density  [mA cm^-^2]')
                end
                ylabel('Excited state density [a.u]')
                legend("CT state","LE state");

            end
        end
        function [X,Y,tableres]=photoluminescence(DV,layernum,Voltage,G)
            CTsum=0;
            for sol = DV.sol_JV
                disp(['Available light intensity ' num2str(sol.params.light_properties.Int)])
                if sol.params.light_properties.Int==G
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    
                    J = dfana.calcJ(sol);
                    Vapp = dfana.calcVapp(sol);
                    if Voltage==0
                        Voltageapp=interp1(J.tot(:,end),Vapp,0);
                        time=find(Vapp>Voltageapp,1);
                        CTsum=mean(trapz(x(x>XL & x<XR), CT(time ,x>XL & x<XR), 2));
                        Exsum=mean(trapz(x(x>XL & x<XR), Ex(time,x>XL & x<XR), 2));
                        %                         Voltageapp=mean(Vapp(J.tot(:,end)<-min(J.tot(:,end))*0.1 & J.tot(:,end)>min(J.tot(:,end))*0.1));
                        CurrInjected=0;
                        tableres=[CurrInjected,G,Voltageapp];
                        
                    elseif max(Vapp>Voltage*0.99 & Vapp<Voltage*1.01)
                        CTsum=mean(trapz(x(x>XL & x<XR), CT(Vapp>Voltage*0.99 & Vapp<Voltage*1.01 ,x>XL & x<XR), 2));
                        Exsum=mean(trapz(x(x>XL & x<XR), Ex(Vapp>Voltage*0.99 & Vapp<Voltage*1.01 ,x>XL & x<XR), 2));
                        CurrInjected=mean(J.tot(Vapp>Voltage*0.99 & Vapp<Voltage*1.01,end))*1e3;
                        tableres=[CurrInjected,G,Voltage];
                        Voltageapp=Voltage;
                        
                    else
                        disp("the JV did not run until the desired voltage")
                    end
                    
                end
            end
            if CTsum==0
                disp("the dark JV does not exist")
            else
                krE=DV.Prec.params.CT.results.krE*CTsum+DV.Prec.params.Ex.results.krE*Exsum;
                tableres(end+1)=max(krE);
                semilogy(DV.Prec.const.Edistribution,krE)
                hold on
                semilogy(DV.Prec.const.Edistribution,DV.Prec.params.CT.results.krE*CTsum)
                semilogy(DV.Prec.const.Edistribution,DV.Prec.params.Ex.results.krE*Exsum)
                X=DV.Prec.const.Edistribution;
                Y=krE/max(krE);
                xlabel('Energy [eV]')
                ylabel('Photoluminescence Emission  [a.u]')
                ylim([max(krE)*1e-3, max(krE)])
                legend("ToT","From CT","FromEx")
                title(['Photoluminescence at ' num2str(Voltageapp) ' V under ' num2str(G) ' LI and injected current ' num2str(CurrInjected) 'mA cm-2'])
                Rec_Rate_rad=DV.Prec.params.Ex.results.krTot*Exsum+DV.Prec.params.CT.results.krTot*CTsum;
                Rec_Rate_nrad=DV.Prec.params.Ex.results.knr*Exsum+DV.Prec.params.CT.results.knr*CTsum;
                Prec=DV.Prec;
                Prec.results.Qi=(Rec_Rate_rad)/(Rec_Rate_nrad+Rec_Rate_rad);
                Prec.results.Qe=1/((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi);
                Prec.results.Dvnr=Prec.const.kb*Prec.const.T*(log((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi));
                DV.Prec=Prec;
                disp(['non radiative voltage loss is ' num2str(Prec.results.Dvnr) ' V']);
            end
        end
        function [X,Y,tableres]=photoluminescence_mult(DV,layernum,Voltage,G,label)
            CTsum=0;
            for sol = DV.sol_JV
                disp(['Available light intensity ' num2str(sol.params.light_properties.Int)])
                if sol.params.light_properties.Int==G
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    
                    J = dfana.calcJ(sol);
                    Vapp = dfana.calcVapp(sol);
                    if Voltage==0
                        Voltageapp=interp1(J.tot(:,end),Vapp,0);
                        time=find(Vapp>Voltageapp,1);
                        CTsum=mean(trapz(x(x>XL & x<XR), CT(time ,x>XL & x<XR), 2));
                        Exsum=mean(trapz(x(x>XL & x<XR), Ex(time,x>XL & x<XR), 2));
                        %                         Voltageapp=mean(Vapp(J.tot(:,end)<-min(J.tot(:,end))*0.1 & J.tot(:,end)>min(J.tot(:,end))*0.1));
                        CurrInjected=0;
                        tableres=[CurrInjected,G,Voltageapp];
                        
                    elseif max(Vapp>Voltage-0.05 & Vapp<Voltage+0.05)
                        CTsum=mean(trapz(x(x>XL & x<XR), CT(Vapp>Voltage-0.05 & Vapp<Voltage+0.05,x>XL & x<XR), 2));
                        Exsum=mean(trapz(x(x>XL & x<XR), Ex(Vapp>Voltage-0.05 & Vapp<Voltage+0.05 ,x>XL & x<XR), 2));
                        CurrInjected=mean(J.tot(Vapp>Voltage*0.99 & Vapp<Voltage*1.01,end))*1e3;
                        tableres=[CurrInjected,G,Voltage];
                        Voltageapp=Voltage;
                        
                    else
                        disp("the JV did not run until the desired voltage")
                    end
                    
                end
            end
            if CTsum==0
                disp("the dark JV does not exist")
            else
                krE=DV.Prec.params.CT.results.krE*CTsum+DV.Prec.params.Ex.results.krE*Exsum;
                tableres(end+1)=max(krE);
                semilogy(DV.Prec.const.Edistribution,krE)

                X=DV.Prec.const.Edistribution;
                Y=krE;
                xlabel('Energy [eV]')
                ylabel('Photoluminescence Emission  [a.u]')
                ylim([max(krE)*1e-1, max(krE)])

                title(['Photoluminescence at under ' num2str(G) ' LI '])
                Rec_Rate_rad=DV.Prec.params.Ex.results.krTot*Exsum+DV.Prec.params.CT.results.krTot*CTsum;
                Rec_Rate_nrad=DV.Prec.params.Ex.results.knr*Exsum+DV.Prec.params.CT.results.knr*CTsum;
                Prec=DV.Prec;
                Prec.results.Qi=(Rec_Rate_rad)/(Rec_Rate_nrad+Rec_Rate_rad);
                Prec.results.Qe=1/((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi);
                Prec.results.Dvnr=Prec.const.kb*Prec.const.T*(log((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi));
                DV.Prec=Prec;
                                lg=legend;
                lg.String{end}=label;
                disp(['non radiative voltage loss is ' num2str(Prec.results.Dvnr) ' V']);
            end
        end
        function photoluminescence_Sweep(DV,layernum,Vstar,Vend,Step,G)
            figure
            for Voltage=Vstar:Step:Vend
                CTsum=0;
                
                for sol = DV.sol_JV
                    disp(['Available light intensity ' num2str(sol.params.light_properties.Int)])
                    if sol.params.light_properties.Int==G
                        [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                        %                         tstart=sol.params.pulse_properties.tstart;
                        %                         tpulse=sol.params.pulse_properties.pulselen;
                        XR=sol.params.Layers{layernum}.XR;
                        XL=sol.params.Layers{layernum}.XL;
                        
                        %                         J = dfana.calcJ(sol);
                        Vapp = dfana.calcVapp(sol);
                        try
                            CTsum=mean(trapz(x(x>XL & x<XR), interp1(Vapp, CT(: ,x>XL & x<XR),Voltage), 2));
                            Exsum=mean(trapz(x(x>XL & x<XR), interp1(Vapp, Ex(: ,x>XL & x<XR),Voltage), 2));
                        catch
                            disp("the JV did not run until the desired voltage")
                        end
                        if CTsum==0 || isnan(CTsum)
                            disp("the dark JV does not exist")
                        else
                            krE=DV.Prec.params.CT.results.krE*CTsum+DV.Prec.params.Ex.results.krE*Exsum;
                            
                            plot(DV.Prec.const.Edistribution,krE)
                            hold on
                            %                     hold on
                            %                     semilogy(DV.Prec.const.Edistribution,DV.Prec.params.CT.results.krE*CTsum)
                            %                     semilogy(DV.Prec.const.Edistribution,DV.Prec.params.Ex.results.krE*Exsum)
                            
                            xlabel('Energy [eV]')
                            ylabel('Photoluminescence Emission  [a.u]')
                            ylim([max(krE)*1e-3, max(krE)])
                            lg=legend;
                            lg.String{end}=[ num2str(Voltage) ' V'];
                            %                     legend("ToT","From CT","FromEx")
                            title(['Photoluminescence under ' num2str(G) ' LI'])
                            Rec_Rate_rad=DV.Prec.params.Ex.results.krTot*Exsum+DV.Prec.params.CT.results.krTot*CTsum;
                            Rec_Rate_nrad=DV.Prec.params.Ex.results.knr*Exsum+DV.Prec.params.CT.results.knr*CTsum;
                            Prec=DV.Prec;
                            Prec.results.Qi=(Rec_Rate_rad)/(Rec_Rate_nrad+Rec_Rate_rad);
                            Prec.results.Qe=1/((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi);
                            Prec.results.Dvnr=Prec.const.kb*Prec.const.T*(log((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi));
                            DV.Prec=Prec;
                            disp(['non radiative voltage loss is ' num2str(Prec.results.Dvnr) ' V']);
                        end
                    end
                end
                
            end
        end
        function DV=photoluminescence_Voc(DV,layernum,G)
            CTsum=0;
            for sol = DV.ssol_Voc
                disp(['Available light intensity ' num2str(sol.params.light_properties.Int)])
                if sol.params.light_properties.Int==G
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    
                    
                    CTsum=mean(trapz(x(x>XL & x<XR), CT(end,x>XL & x<XR), 2));
                    Exsum=mean(trapz(x(x>XL & x<XR), Ex(end ,x>XL & x<XR), 2));
                    
                    
                end
            end
            if CTsum==0
                disp("the voc solution does not exist")
            else
                krE=DV.Prec.params.CT.results.krE*CTsum+DV.Prec.params.Ex.results.krE*Exsum;
                figure
                semilogy(DV.Prec.const.Edistribution,krE)
                hold on
                semilogy(DV.Prec.const.Edistribution,DV.Prec.params.CT.results.krE*CTsum)
                semilogy(DV.Prec.const.Edistribution,DV.Prec.params.Ex.results.krE*Exsum)
                
                xlabel('Energy [eV]')
                ylabel('Photoluminescence Emission  [a.u]')
                ylim([max(krE)*1e-3, max(krE)])
                legend("ToT","From CT","FromEx")
                title(['Photoluminescence at Voc under ' num2str(G) ' LI'])
                Rec_Rate_rad=DV.Prec.params.Ex.results.krTot*Exsum+DV.Prec.params.CT.results.krTot*CTsum;
                Rec_Rate_nrad=DV.Prec.params.Ex.results.knr*Exsum+DV.Prec.params.CT.results.knr*CTsum;
                Prec=DV.Prec;
                Prec.results.Qi=(Rec_Rate_rad)/(Rec_Rate_nrad+Rec_Rate_rad);
                Prec.results.Qe=1/((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi);
                Prec.results.Dvnr=Prec.const.kb*Prec.const.T*(log((1+(Prec.results.pe-1)*Prec.results.Qi)/Prec.results.pe/Prec.results.Qi));
                DV.Prec=Prec;
                disp(['non radiative voltage loss is ' num2str(Prec.results.Dvnr) ' V']);
            end
        end
        function [X,Y]=TAS_GSB_norm(DV,layernum,G)
            for sol = DV.ssol_TAS
                if sol.params.light_properties.Int==G
                    
                    % Plot the integrated space charge density in Coulombs [Ccm-2] as a function of time
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
                    Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
                    nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2);
                    %                     figure
                    %                     semilogx(t, (CTsum-CTsum(1))./max((CTsum-CTsum(1))))%/max((Exsum-Exsum(1))))
                    t=(t-tstart)*1e12;
                    
                    semilogx(t, (Exsum-Exsum(1))./max((Exsum-Exsum(1))))
                    
                    lg=legend;
                    lg.String{end}="Model Exp pop";
                    hold on
                    %                     semilogx(t, (nsum-nsum(1)))%/max((Exsum-Exsum(1))))
                    semilogx(t, ((nsum-nsum(1))+(CTsum-CTsum(1)))./max((nsum-nsum(1))+(CTsum-CTsum(1))))%/max((Exsum-Exsum(1))))
                    X=t;
                    Y=((nsum-nsum(1))+(CTsum-CTsum(1)))./max((nsum-nsum(1))+(CTsum-CTsum(1)));
                    xlabel('Time [ps]')
                    ylabel('Normalised Excited state density [cm-2]')
                    %                     xlim([max(t(1),1e-12), t(end)])
                    lg=legend;
                    lg.String{end}="Model GSB";
                end
            end
        end
        function TAS_GSB(DV,layernum,G)
            for sol = DV.ssol_TAS
                if sol.params.light_properties.Int==G
                    
                    % Plot the integrated space charge density in Coulombs [Ccm-2] as a function of time
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    tstart=sol.params.pulse_properties.tstart;
                    tpulse=sol.params.pulse_properties.pulselen;
                    XR=sol.params.Layers{layernum}.XR;
                    XL=sol.params.Layers{layernum}.XL;
                    CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
                    Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
                    nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2);
                    figure
                    t=t*1e12;
                    semilogx(t, (CTsum-CTsum(1)))%/max((Exsum-Exsum(1))))
                    hold on
                    semilogx(t, (Exsum-Exsum(1)))%/max((Exsum-Exsum(1))))
                    semilogx(t, (nsum-nsum(1)))%/max((Exsum-Exsum(1))))
                    semilogx(t, (nsum-nsum(1))+(CTsum-CTsum(1)))%/max((Exsum-Exsum(1))))
                    
                    xlabel('Time [ps]')
                    ylabel('Normalised Excited state density [cm-2]')
                    xlim([max(t(1),1e-12), t(end)])
                    legend("CT","Ex","electron","GSB")
                end
            end
            %             figure(17)
            %             semilogx(t-tstart, (CTsum-CTsum(1))/max((Exsum-Exsum(1))))
            %             hold on
            %             semilogx(t-tstart,(Exsum-Exsum(1))/max((Exsum-Exsum(1))))
            %             semilogx(t-tstart, (nsum-nsum(1))/max((Exsum-Exsum(1))))
            %
            %             xlabel('Time [s]')
            %             ylabel('Normalised Excited state density [cm-2]')
            %             xlim([t(1), t(end)])
            %             legend("CT","Ex","electron")
            %             figure(18)
            %             semilogx(t-tstart-tpulse, (CTsum-CTsum(1))/max((Exsum-Exsum(1))))
            %             hold on
            %             semilogx(t-tstart-tpulse,(Exsum-Exsum(1))/max((Exsum-Exsum(1))))
            %             semilogx(t-tstart-tpulse, (nsum-nsum(1))/max((Exsum-Exsum(1))))
            %
            %             xlabel('Time [s]')
            %             ylabel('Normalised Excited state density [cm-2]')
            %             xlim([t(1), t(end)])
            %             legend("CT","Ex","electron")
        end
        function N0=CE(DV,G,layernum)
            N0=0;
            for sol = DV.ssol_TPV
                if sol.params.light_properties.Int==G
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    [~, ~, Efn, Efp] = dfana.QFLs(sol);
                    VQFL = Efn(:, (length(x)+1)/2) - Efp(:, 1);
                    
                    XR=par.Layers{layernum}.XR;
                    XL=par.Layers{layernum}.XL;
                    nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2)/(XR-XL);
                    Voc=VQFL(1);
                    for sol0= DV.sol_JV
                        if sol0.params.light_properties.Int<1e-5
                            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol0);
                            [~, ~, Efn, Efp] = dfana.QFLs(sol0);
                            VQFL0 = Efn(:, end) - Efp(:, 1);
                            
                            nsum0=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2)/(XR-XL);
                            N0eq=min(nsum0(VQFL>Voc*0.95 & VQFL<Voc*1.05));
                        end
                    end
                    N0=nsum(1)-N0eq;
                end
            end
        end
        function [TQ1,TQ2,TTPV,N0]=TPV(DV,G,layernum)
            for sol = DV.ssol_TPV
                if sol.params.light_properties.Int==G
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    [~, ~, Efn, Efp] = dfana.QFLs(sol);
                    VQFL = Efn(:, (length(x)+1)/2) - Efp(:, 1);
                    VQFL=VQFL-VQFL(1);
                    rho = dfana.calcrho(sol);
                    tstart=par.pulse_properties.tstart;
                    tpulse=par.pulse_properties.pulselen;
                    XR=par.Layers{layernum}.XR;
                    XL=par.Layers{layernum}.XL;
                    CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
                    Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
                    rhosum=-trapz(x(x>XL & x<XR), rho(:,x>XL & x<XR), 2);
                    nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2)/(XR-XL);
                    N0=nsum(1);
                    nsum=nsum-nsum(1);
                    rhosum=rhosum-rhosum(1);
                    
                    semilogy(t-tstart, VQFL/max(VQFL))%/max((Exsum-Exsum(1))))
                    hold on
                    semilogy(t-tstart, nsum/max(nsum))%/max((Exsum-Exsum(1))))
                    semilogy(t-tstart, CTsum/max(CTsum))%/max((Exsum-Exsum(1))))
                    semilogy(t-tstart, Exsum/max(Exsum))%/max((Exsum-Exsum(1))))
                    
                    xlabel('Time [s]')
                    ylabel('Normalised signal [a.u]')
                    %                     xlim([max(t(1),1e-12), t(end)])
                    ylim([1e-2,1.1])
                    
                    legend("V_o_c "+num2str(G)+" sun","Q "+num2str(G)+" sun","CT "+num2str(G)+" sun","Ex "+num2str(G)+" sun")
                    
                    %%
                    fo = fitoptions('Method','NonlinearLeastSquares',...
                        'Lower',[0,0,0,0],'Start', [1,1e-6,0.1,1e-8]);
                    ft = fittype('a*exp(-x/b)+c*exp(-x/d)','options',fo);
                    maxQ=find(nsum==max(nsum),1);
                    maxTPV=find(VQFL==max(VQFL),1);
                    maxTPV=maxTPV+2;
                    TPVend=find(t==min(t(t'>t(maxTPV) & VQFL<max(VQFL)*1e-2)),1);
                    f=fit(t(maxQ: TPVend)'-t(maxQ),nsum(maxQ: TPVend)./max(nsum),ft);
                    if min(f.a,f.c)<1.5e-2
                        if f.a>f.c
                            TQ1=f.b;
                            TQ2=f.d;
                        else
                            TQ1=f.d;
                            TQ2=f.b;
                        end
                    else
                        TQ1=min(f.b,f.d);
                        TQ2=max(f.b,f.d);
                    end
                    startPoints=[1,0.01];
                    f=fit(t(maxTPV:TPVend)'-t(maxTPV),VQFL(maxTPV:TPVend)./max(VQFL),'exp1','Start', startPoints);
                    xlim([0,t(TPVend)])
                    TTPV=-1/f.b;
                    title("Generation "+num2str(G)+" T_Q_1 "+num2str(TQ1*1e6)+" T_Q_2 "+num2str(TQ2*1e6)+" us T_T_P_V "+num2str(TTPV*1e6)+" us");
                end
            end
        end
        function TPQ(DV,G,layernum)
            for sol = DV.ssol_TPV
                if sol.params.light_properties.Int==G
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    [~, ~, Efn, Efp] = dfana.QFLs(sol);
                    VQFL = Efn(:, (length(x)+1)/2) - Efp(:, 1);
                    VQFL=VQFL-VQFL(1);
                    rho = dfana.calcrho(sol);
                    tstart=par.pulse_properties.tstart;
                    tpulse=par.pulse_properties.pulselen;
                    XR=par.Layers{layernum}.XR;
                    XL=par.Layers{layernum}.XL;
                    CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
                    Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
                    rhosum=-trapz(x(x>XL & x<XR), rho(:,x>XL & x<XR), 2);
                    nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2)/(XR-XL);
                    N0=nsum(1);
                    nsum=nsum-nsum(1);
                    rhosum=rhosum-rhosum(1);
                    

                    semilogy(t-tstart, nsum)%/max((Exsum-Exsum(1))))
                    hold on
             
                    
                    xlabel('Time [s]')
                    ylabel('Normalised Excess Charge carrier density [cm^-^3]')
                    %                     xlim([max(t(1),1e-12), t(end)])
%                     ylim([1e-2,1.1])
                    
                    legend("V_o_c "+num2str(G)+" sun","Q "+num2str(G)+" sun","CT "+num2str(G)+" sun","Ex "+num2str(G)+" sun")
                    
                    %%
                    
                end
            end
        end
        function [TQ1,TQ2,TTPV,N0]=TPV_EL(DV,G,layernum,holdfig)
            Colorlist=[[237 85 101];[248 172 89];[235 198 200];[26 179 148];[22 138 198];[13 58 89];[13 08 89];[3 58 189];[13 98 89];[100 58 189];[130 98 89]]./255;
            Markers = {'+','o','*','x','v','d','^','s','>','<'};
            if holdfig==1
                ax=gca;
                kk=length(ax.Legend.String)+1;
                Marker_Counter=length(ax.Legend.String)+1;
            else
                figure
                kk=1;
                Marker_Counter=1;
            end
            for sol = DV.ssol_TPV
                if sol.params.light_properties.Int==G
                    [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
                    [~, ~, Efn, Efp] = dfana.QFLs(sol);
                    VQFL = Efn(:, (length(x)+1)/2) - Efp(:, 1);
                    VQFL=VQFL-VQFL(1);
                    rho = dfana.calcrho(sol);
                    tstart=par.pulse_properties.tstart;
                    tpulse=par.pulse_properties.pulselen;
                    XR=par.Layers{layernum}.XR;
                    XL=par.Layers{layernum}.XL;
                    CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
                    Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
                    rhosum=-trapz(x(x>XL & x<XR), rho(:,x>XL & x<XR), 2);
                    nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2)/(XR-XL);
                    N0=nsum(1);
                    nsum=nsum-nsum(1);
                    CTsum=CTsum-CTsum(1);
                    Exsum=Exsum-Exsum(1);
                    rhosum=rhosum-rhosum(1);
                    subplot(2,2,1)
                    semilogy(t-tstart, VQFL/max(VQFL),'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
                    hold on
                    semilogy(t-tstart, nsum/max(nsum),'--','LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
                    
                    
                    xlabel('Time [s]')
                    ylabel('Normalised  transient signal [a.u]')
                    %                     xlim([max(t(1),1e-12), t(end)])
                    ylim([1e-2,1.1])
                    lg=legend();
                    lg.String{end-1}="V_o_c "+num2str(G)+" sun";
                    lg.String{end}="Q "+num2str(G)+" sun";
                    subplot(2,2,2)
                    semilogy(t-tstart, CTsum/max(CTsum),'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
                    hold on
                    semilogy(t-tstart, Exsum/max(Exsum),'--','LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
                    
                    xlabel('Time [s]')
                    ylabel('Normalised  transient signal [a.u]')
                    %                     xlim([max(t(1),1e-12), t(end)])
                    ylim([1e-2,1.1])
                    lg=legend();
                    lg.String{end-1}="CT "+num2str(G)+" sun";
                    lg.String{end}="Ex "+num2str(G)+" sun";
                    
                    subplot(2,2,3)
                    timearray=t-tstart;
                    maxE=1;
                    Luminescence=DV.Prec.params.Ex.results.krE.*Exsum+...
                        DV.Prec.params.CT.results.krE.*CTsum;
                    [peakint,peakpos]=max(Luminescence');
                    semilogy(t-tstart, peakint,'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
                    hold on
                    lg=legend();
                    lg.String{end}=num2str(G)+" sun";
                    subplot(2,2,4)
                    plot(t-tstart, DV.Prec.const.Edistribution(peakpos),'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
                    hold on
                    lg=legend();
                    lg.String{end}=num2str(G)+" sun";
                    ylim([1,2])
                    %
                    %                     for tt=linspace(1e-6,1e-5,10)
                    %
                    %                         try
                    %                             time_counter=find(timearray>tt,1);
                    % %                             semilogy(DV.Prec.const.Edistribution,DV.Prec.params.CT.results.krE*CTsum(time_counter))
                    % %                             semilogy(DV.Prec.const.Edistribution,DV.Prec.params.Ex.results.krE*Exsum(time_counter))
                    %                             semilogy(DV.Prec.const.Edistribution,DV.Prec.params.Ex.results.krE*Exsum(time_counter)+...
                    %                                 DV.Prec.params.CT.results.krE*CTsum(time_counter),'LineWidth',2);
                    %                             maxE=max(maxE,max(0*DV.Prec.params.Ex.results.krE*Exsum(time_counter)+...
                    %                                 DV.Prec.params.CT.results.krE*CTsum(time_counter)));
                    %                             hold on
                    %                             ylim([maxE/1e2,maxE])
                    %                             lg=legend();
                    %                             lg.String{end}="Lumi "+num2str(G)+" sun @ "+ num2str(tt)+" us";
                    %                         catch
                    %                             disp("Error @"+num2str(tt)+" us");
                    %                         end
                    %                     end
                    %%
                    fo = fitoptions('Method','NonlinearLeastSquares',...
                        'Lower',[0,0,0,0],'Start', [1,1e-6,0.1,1e-8]);
                    ft = fittype('a*exp(-x/b)+c*exp(-x/d)','options',fo);
                    maxQ=find(nsum==max(nsum),1);
                    maxTPV=find(VQFL==max(VQFL),1);
                    maxTPV=maxTPV+2;
                    TPVend=find(t==min(t(t'>t(maxTPV) & VQFL<max(VQFL)*1e-2)),1);
                    f=fit(t(maxQ: TPVend)'-t(maxQ),nsum(maxQ: TPVend)./max(nsum),ft);
                    if min(f.a,f.c)<1.5e-2
                        if f.a>f.c
                            TQ1=f.b;
                            TQ2=f.d;
                        else
                            TQ1=f.d;
                            TQ2=f.b;
                        end
                    else
                        TQ1=min(f.b,f.d);
                        TQ2=max(f.b,f.d);
                    end
                    startPoints=[1,0.01];
                    f=fit(t(maxTPV:TPVend)'-t(maxTPV),VQFL(maxTPV:TPVend)./max(VQFL),'exp1','Start', startPoints);
                    TTPV=-1/f.b;
                    subplot(2,2,1)
                    xlim([0,1e-5])
                    subplot(2,2,2)
                    xlim([0,1e-5])
                    subplot(2,2,3)
                    xlim([0,1e-5])
                    subplot(2,2,4)
                    xlim([0,1e-5])
                    
                    title("Generation "+num2str(G)+" T_Q_1 "+num2str(TQ1*1e6)+" T_Q_2 "+num2str(TQ2*1e6)+" us T_T_P_V "+num2str(TTPV*1e6)+" us");
                end
            end
        end
        function PL_T(DV,sol,layernum,holdfig,name)
            %             close all
            Colorlist=[[237 85 101];[248 172 89];[235 198 200];[26 179 148];[22 138 198];[13 58 89];[13 08 89];[3 58 189];[13 98 89];[100 58 189];[130 98 89]]./255;
            Markers = {'+','o','*','x','v','d','^','s','>','<'};
            if holdfig==1
                ax=gca;
                kk=length(ax.Legend.String)+1;
                Marker_Counter=length(ax.Legend.String)+1;
            else
                figure
                kk=1;
                Marker_Counter=1;
            end
            Vapp = dfana.calcVapp(sol);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            rho = dfana.calcrho(sol);
            XR=par.Layers{layernum}.XR;
            XL=par.Layers{layernum}.XL;
            CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
            Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
            rhosum=-trapz(x(x>XL & x<XR), rho(:,x>XL & x<XR), 2);
            nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2)/(XR-XL);
            subplot(2,2,1)
                        semilogx(t+1e-8, Vapp/max(Vapp),'-*','LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))

            hold on
            
            semilogx(t+1e-8, (CTsum-CTsum(1))/max(CTsum),'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
            semilogx(t+1e-8, (Exsum-Exsum(1))/max(Exsum),'--','LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
            xlabel('Time [s]')
            ylabel('Normalised  transient signal [a.u]')
            ylim([1e-2,1.1])
            xlim([1e-8,max(t)])
            lg=legend();
            lg.String{end-2}="Voltage applied";
            
            lg.String{end-1}=name+" CT ";
            lg.String{end}=name+" Ex ";
            
            subplot(2,2,2)
            
            Luminescence=DV.Prec.params.Ex.results.krE.*Exsum+...
                DV.Prec.params.CT.results.krE.*CTsum;
            [peakint,peakpos]=max(Luminescence');
            loglog(t, peakint/max(peakint),'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
            [peakint_diff,peakpos_diff]=max((Luminescence-Luminescence(1,:))');
            hold on
            loglog(t, peakint_diff/max(peakint_diff),'--','LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
            
            
            hold on
            lg=legend();
            
            lg.String{end-1}=name+"total";
            lg.String{end}=name+"diff";
            
            xlabel('Time [s]')
            ylabel('peak intensity [a.u]')
            ylim([1e-2,1.1])
            xlim([min(t(1),1e-7),max(t)])
            subplot(2,2,3)
                      

            semilogx(t, DV.Prec.const.Edistribution(peakpos),'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
              hold on
            plot(t, DV.Prec.const.Edistribution(peakpos_diff),'--','LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
            ylabel('peak energie [a.u]')
            xlabel('Time [s]')
            lg=legend();

            lg.String{end-1}=name+"total";
            lg.String{end}=name+"diff";
            ylim([1,2])
            subplot(2,2,4)
            %
            maxE=1;
            for tt=linspace(1e-7,1e-5,3)
                
                try
                    time_counter=find(t>tt,1);
                    %                             semilogy(DV.Prec.const.Edistribution,DV.Prec.params.CT.results.krE*CTsum(time_counter))
                    %                             semilogy(DV.Prec.const.Edistribution,DV.Prec.params.Ex.results.krE*Exsum(time_counter))
                    y=DV.Prec.params.Ex.results.krE*Exsum(time_counter)+...
                        DV.Prec.params.CT.results.krE*CTsum(time_counter);
                    semilogy(DV.Prec.const.Edistribution,y,strcat('-',Markers{Marker_Counter}),'LineWidth',2,'Color',Colorlist(kk,:),'MarkerIndices',1:10:length(y));
                    hold on
                    maxE=max(maxE,max(DV.Prec.params.Ex.results.krE*Exsum(time_counter)+...
                        DV.Prec.params.CT.results.krE*CTsum(time_counter)));
                    hold on
                    ylim([maxE/1e2,maxE])
                    lg=legend();
                    lg.String{end}=name+"  @ "+ num2str(tt)+" us";
                    Marker_Counter=Marker_Counter+1;
                catch
                    disp("Error @"+num2str(tt)+" us");
                end
            end
        end
        function transient_EL(DV,sol,layernum,holdfig,name)
            %             close all
            Colorlist=[[237 85 101];[248 172 89];[235 198 200];[26 179 148];[22 138 198];[13 58 89];[13 08 89];[3 58 189];[13 98 89];[100 58 189];[130 98 89]]./255;
            Markers = {'+','o','*','x','v','d','^','s','>','<'};
            if holdfig==1
                ax=gca;
                kk=length(ax.Legend.String)+1;
                Marker_Counter=length(ax.Legend.String)+1;
            else
                figure
                kk=1;
                Marker_Counter=1;
            end
            Vapp = dfana.calcVapp(sol);
            [u,t,x,par,n,p,CT,Ex,V] = dfana.splitsol(sol);
            rho = dfana.calcrho(sol);
            XR=par.Layers{layernum}.XR;
            XL=par.Layers{layernum}.XL;
            CTsum=trapz(x(x>XL & x<XR), CT(:,x>XL & x<XR), 2);
            Exsum=trapz(x(x>XL & x<XR), Ex(:,x>XL & x<XR), 2);
            rhosum=-trapz(x(x>XL & x<XR), rho(:,x>XL & x<XR), 2);
            nsum=trapz(x(x>XL & x<XR), n(:,x>XL & x<XR), 2)/(XR-XL);
           if  holdfig==1
           else
                        semilogx(t, Vapp/max(Vapp),'-*','LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
                                              lg=legend();
            lg.String{end}="voltage step";
                      hold on
           end
            
            J = dfana.calcJ(sol);

                semilogx(t, J.tot(:,end)./max(J.tot(:,end)),'-o','LineWidth',2,'Color',Colorlist(kk+1,:))
              lg=legend();
            lg.String{end}="current"+name;
            
            Luminescence=DV.Prec.params.Ex.results.krE.*Exsum+...
                DV.Prec.params.CT.results.krE.*CTsum;
            [peakint,peakpos]=max(Luminescence');
  
            semilogx(t, peakint/max(peakint),'LineWidth',2,'Color',Colorlist(kk,:))%/max((Exsum-Exsum(1))))
            
            
            
            hold on
            lg=legend();
            Vstep=sol.params.Experiment_prop.V_fun_arg(2)-sol.params.Experiment_prop.V_fun_arg(1);
            lg.String{end}=name+" Vstep "+num2str(Vstep)+" V";
            
            xlabel('Time [s]')
            ylabel('peak intensity [a.u]')
            ylim([1e-2,1.1])
            xlim([min(t(1),1e-7),max(t)])
           
        end
        function [sol, tarr, pointtype, xrange] = sortarg(args)
            
            if length(args) == 1
                sol = args{1};
                tarr = sol.t(end);
                pointtype = 't';
                xrange = [sol.x(1), sol.x(end)]*1e7;    % converts to nm
            elseif length(args) == 2
                sol = args{1};
                tarr = args{2};
                pointtype = 't';
                xrange = [sol.x(1), sol.x(end)]*1e7;    % converts to nm
            elseif length(args) == 3
                sol = args{1};
                tarr = args{2};
                xrange = args{3};
                pointtype = 't';
            end
        end
        
        function x2d(sol, xmesh, variables, legstr, linestyle, ylab, tarr, xrange, logx, logy)
            % SOL = solution structure
            % VARIABLES is an array containing the variables for plotting
            % LEGSTR is the legend string
            % YLAB = y-axis label
            % TARR- array of times
            % XRANGE - limits of the plot as a two element vector
            % LOGX, LOGY - switches for log axes
            ax = gca;
            if ishold(ax) == 0
                cla(ax);    % Clear current axis if held
            end
            par = sol.params;
            xnm = xmesh*1e7;
            
            vmin = min(min(cell2mat(variables)));
            vmax = max(max(cell2mat(variables)));
            
            if vmin == 0 && vmax == 0
                vmin = -1;
                vmax = 1;
            end
            vrange = vmax-vmin;
            if isempty(findobj(ax,'Type','patch'))
                switch logy
                    case 0
                        dfplot.colourblocks(sol, [vmin-(vrange*0.2), vmax+(vrange*0.2)]);
                    case 1
                        dfplot.colourblocks(sol, [0.1*vmin, 10*vmax]);
                end
            end
            
            vmin_tarr = zeros(length(tarr),length(variables));
            vmax_tarr = zeros(length(tarr),length(variables));
            h = zeros(1, length(variables));
            
            for i = 1:length(tarr)
                % find the time
                p1 = find(sol.t <= tarr(i));
                p1 = p1(end);
                for jj = 1:length(variables)
                    vtemp = variables{jj};
                    
                    vmin_tarr(i,jj) = min(vtemp(p1, :));
                    vmax_tarr(i,jj) = max(vtemp(p1, :));
                    
                    h(i,jj) = plot(xnm, variables{jj}(p1, :), char(linestyle(jj)));
                    hold on
                end
            end
            xlabel('Position [nm]')
            ylabel(ylab)
            if logy == 1
                set(gca, 'YScale','log');
            end
            if logx == 1
                set(gca, 'XScale','log');
            end
            if length(variables) == 1
                mystr = [];
                for i = 1:length(tarr)
                    mystr = [mystr, string(['t = ', num2str(tarr(i)), ' s'])];
                end
                lgd = legend(h, mystr);
            else
                lgd = legend(h(1,:), legstr);
            end
            lgd.FontSize = 12;
            xlim([xrange(1), xrange(2)])
            ymin = min(min(vmin_tarr));
            ymax = max(max(vmax_tarr));
            yrange = ymax - ymin;
            if ymin == 0 && ymax == 0
            else
                switch logy
                    case 0
                        if yrange == 0
                            ylim([ymin*0.9, ymax*1.1]);
                        else
                            ylim([ymin-(yrange*0.2), ymax+(yrange*0.2)]);
                        end
                    case 1
                        ylim([0.1*ymin, 10*ymax])
                end
            end
            set(gca, 'Layer', 'top')
            box on
            hold off
        end
    end
end

