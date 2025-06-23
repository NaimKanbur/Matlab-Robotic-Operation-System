
function robot_gui_pathplanner_snapshot_fixed()
    % STL dizin yolu
    stlPath = 'meshes';

    % STL dosyalarını oku
    stand = stlread(fullfile(stlPath, 'stand.stl'));
    govde = stlread(fullfile(stlPath, 'govde.stl'));
    eklem = stlread(fullfile(stlPath, 'eklem.stl'));
    kol   = stlread(fullfile(stlPath, 'kol.stl'));

    % Dönme merkezleri
    h_govde = 200;
    pivot_eklem = [0 0 960];
    pivot_kol = [0 0 1360.0002];

    % GUI penceresi
    f = figure('Name','Naim Path Planner - Snapshot (Fixed)','NumberTitle','off','Position',[100 100 1300 750]);
    ax = axes('Parent',f,'Position',[0.05 0.3 0.6 0.65]);
    axis equal; view(3);
    camlight; lighting gouraud;
    xlabel('X'); ylabel('Y'); zlabel('Z');

    angles = [0, 0, 0];
    maxKayit = 5;
    kayitlar = cell(1, maxKayit);
    kayitImgs = gobjects(1, maxKayit);
    silBtns = gobjects(1, maxKayit);

    % Sliderlar
    s1 = uicontrol('Style','slider','Min',-180,'Max',180,'Value',0,...
                   'Position',[700 550 300 20],'Callback',@(src,~) updateRobot());
    s2 = uicontrol('Style','slider','Min',-180,'Max',180,'Value',0,...
                   'Position',[700 510 300 20],'Callback',@(src,~) updateRobot());
    s3 = uicontrol('Style','slider','Min',-180,'Max',180,'Value',0,...
                   'Position',[700 470 300 20],'Callback',@(src,~) updateRobot());

    uicontrol('Style','text','Position',[700 570 100 20],'String','Govde (Z)');
    uicontrol('Style','text','Position',[700 530 100 20],'String','Eklem (Y)');
    uicontrol('Style','text','Position',[700 490 100 20],'String','Kol (Y)');

    uicontrol('Style','pushbutton','Position',[700 430 100 30],'String','Konum Kaydet',...
              'Callback', @(src,~) kaydetKonum());
    uicontrol('Style','pushbutton','Position',[820 430 100 30],'String','Parkuru Başlat',...
              'Callback', @(src,~) calistirParkur());

    for i = 1:maxKayit
        x = 100 + (i-1)*200;
        bg = uipanel('Parent',f,'Position',[(x-50)/1300 0.03 0.12 0.2],'BackgroundColor',[0.95 0.95 0.95]);
        kayitImgs(i) = axes('Parent', bg, 'Position',[0.1 0.3 0.8 0.6]);
        axis(kayitImgs(i), 'off');
        silBtns(i) = uicontrol('Parent',bg,'Style','pushbutton','String','x',...
                        'Position',[80 5 30 20],'Callback', @(src,~) silKonum(i));
    end

    updateRobot();

    function updateRobot()
        angles(1) = deg2rad(s1.Value);
        angles(2) = deg2rad(s2.Value);
        angles(3) = deg2rad(s3.Value);
        cla(ax); hold(ax, 'on');
        trisurf(stand,'FaceColor','red','EdgeColor','none','FaceAlpha',0.9,'Parent',ax);
        T1 = makehgtform('translate', [0 0 h_govde]) * makehgtform('zrotate', angles(1));
        plotSTL(govde, T1, 'cyan');
        T2 = T1 * makehgtform('translate', pivot_eklem) * makehgtform('yrotate', angles(2)) * makehgtform('translate', -pivot_eklem);
        plotSTL(eklem, T2, 'yellow');
        T3 = T2 * makehgtform('translate', pivot_kol) * makehgtform('yrotate', angles(3)) * makehgtform('translate', -pivot_kol);
        plotSTL(kol, T3, 'magenta');
        hold(ax, 'off');
        axis(ax, 'equal'); % geniş alan yok
        view(ax, 3);
    end

    function plotSTL(fv, T, color)
        v = fv.Points;
        v_hom = [v, ones(size(v,1),1)] * T';
        trisurf(fv.ConnectivityList, v_hom(:,1), v_hom(:,2), v_hom(:,3), ...
                'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', 0.9, 'Parent', ax);
    end

    function kaydetKonum()
        for i = 1:maxKayit
            if isempty(kayitlar{i})
                kayitlar{i} = [s1.Value, s2.Value, s3.Value];
                F = getframe(ax);
                axes(kayitImgs(i));
                imshow(F.cdata);
                break;
            end
        end
    end

    function silKonum(index)
        kayitlar(index) = [];
        kayitlar{maxKayit} = [];
        for i = 1:maxKayit
            cla(kayitImgs(i));
            if ~isempty(kayitlar{i})
                temp = kayitlar{i};
                s1.Value = temp(1); s2.Value = temp(2); s3.Value = temp(3);
                updateRobot();
                F = getframe(ax);
                axes(kayitImgs(i));
                imshow(F.cdata);
            end
        end
    end

    function calistirParkur()
        for i = 1:maxKayit
            if isempty(kayitlar{i}), continue; end
            hedef = kayitlar{i};
            adimSayisi = 50;
            g0 = s1.Value; e0 = s2.Value; k0 = s3.Value;
            for t = linspace(0,1,adimSayisi)
                s1.Value = (1-t)*g0 + t*hedef(1);
                s2.Value = (1-t)*e0 + t*hedef(2);
                s3.Value = (1-t)*k0 + t*hedef(3);
                updateRobot();
                pause(0.02);
            end
        end
    end
end
