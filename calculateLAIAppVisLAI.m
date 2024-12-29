function calculateLAIApp555e
    % 创建主窗口
    main_window = figure('Name', '计算叶面积指数 (LAI)', ...
                         'Position', [100, 100, 1000, 600], ...
                         'MenuBar', 'none', ...
                         'ToolBar', 'none', ...
                          'NumberTitle', 'off');

    % 创建控件面板
    control_panel = uipanel('Parent', main_window, ...
                            'Title', '设置', ...
                            'Position', [0.02, 0.55, 0.96, 0.43]);

    % 添加控件到控件面板
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '导入图片:', ...
              'Position', [30, 200, 100, 20]);

    image_path_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
                                 'Position', [140, 200, 300, 25]);

    browse_button = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
                              'String', '浏览', ...
                              'Position', [460, 200, 60, 25], ...
                              'Callback', @browseImage);

    % 添加边缘提取方法选择框
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '边缘提取方法:', ...
              'Position', [30, 175, 100, 20]);
    edge_method_popup = uicontrol('Parent', control_panel, 'Style', 'popup', ...
                                   'String', {'Canny', 'Sobel', 'Laplacian'}, ...
                                   'Position', [140, 175, 100, 25]);

    % 其他控件
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '摄影距离 (米):', ...
              'Position', [30, 150, 100, 20]);
    distance_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
                              'Position', [140, 150, 100, 25]);

    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '传感器宽度 (毫米):', ...
              'Position', [260, 150, 120, 20]);
    sensor_width_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
                                   'Position', [390, 150, 100, 25]);

    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '传感器高度 (毫米):', ...
              'Position', [510, 150, 120, 20]);
    sensor_height_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
                                    'Position', [640, 150, 100, 25]);

    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '焦距 (毫米):', ...
              'Position', [30, 100, 100, 20]);
    focal_length_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
                                   'Position', [140, 100, 100, 25]);

    calculate_button = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
                                 'String', '计算 LAI', ...
                                 'Position', [250, 50, 100, 30], ...
                                 'Callback', @calculateLAI);

    result_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                            'String', '', ...
                            'Position', [30, 10, 700, 30], ...
                            'HorizontalAlignment', 'left');

    % 显示视场角的标签
    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '水平视场角 (°):', ...
              'Position', [550, 100, 120, 20]);
    horizontal_fov_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                     'String', '0', ...
                                     'Position', [670, 100, 100, 20]);

    uicontrol('Parent', control_panel, 'Style', 'text', 'String', '垂直视场角 (°):', ...
              'Position', [550, 75, 120, 20]);
    vertical_fov_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                   'String', '0', ...
                                   'Position', [670, 75, 100, 20]);

    % 创建图像显示面板
    image_panel = uipanel('Parent', main_window, ...
                          'Title', '图片显示', ...
                          'Position', [0.02, 0.05, 0.3, 0.5]);
    image_axes = axes('Parent', image_panel, 'Position', [0.1, 0.1, 0.8, 0.8]);

    % 创建 G 函数显示面板
    g_panel = uipanel('Parent', main_window, ...
                      'Title', 'G 函数', ...
                      'Position', [0.66, 0.05, 0.32, 0.5]);
    g_axes = axes('Parent', g_panel, 'Position', [0.1, 0.1, 0.8, 0.8]);

    % 全局变量
    global rect_info is_dragging img_data; 
    rect_info = [];
    is_dragging = false;
    img_data = []; 

    % 浏览图片按钮的回调函数
    function browseImage(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp', '支持的图片文件'}, '选择图片文件');
        if filename ~= 0
            fullpath = fullfile(pathname, filename);
            set(image_path_edit, 'String', fullpath);
            img_data = imread(fullpath);
            imshow(img_data, 'Parent', image_axes, 'InitialMagnification', 'fit');
            rect_info = []; 
            set(main_window, 'WindowButtonDownFcn', @updateRectInfo); % Enable area selection
        end
    end

    % 计算 LAI 的回调函数
    function calculateLAI(~, ~)
        disp('计算 LAI 被触发');  % 调试输出
        distance = str2double(get(distance_edit, 'String'));
        sensor_width = str2double(get(sensor_width_edit, 'String'));
        sensor_height = str2double(get(sensor_height_edit, 'String'));
        focal_length = str2double(get(focal_length_edit, 'String'));

        if isnan(distance) || isnan(sensor_width) || isnan(sensor_height) || isnan(focal_length) || ...
           distance <= 0 || sensor_width <= 0 || sensor_height <= 0 || focal_length <= 0
            errordlg('请输入有效的参数值。', '输入错误', 'modal');
            return;
        end

        if isempty(rect_info)
            errordlg('请先选择裁剪区域。', '区域错误', 'modal');
            return;
        end

        horizontal_fov = calculateFOV(sensor_width, focal_length);
        vertical_fov = calculateFOV(sensor_height, focal_length);
        
        % 更新视场角文本框
        set(horizontal_fov_text, 'String', num2str(horizontal_fov, '%.2f'));
        set(vertical_fov_text, 'String', num2str(vertical_fov, '%.2f'));

        try
            corn_image = img_data; 
            imshow(corn_image, 'Parent', image_axes, 'InitialMagnification', 'fit');

            rect = rect_info;

            width_pixels = rect(3);
            height_pixels = rect(4);

            actual_width = (width_pixels / sensor_width) * (distance / 1000);
            actual_height = (height_pixels / sensor_height) * (distance / 1000);

            text(image_axes, rect(1), rect(2) - 10, ...
                ['宽度: ', num2str(actual_width, '%.2f'), ' m'], ...
                'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');
            text(image_axes, rect(1) + width_pixels + 5, rect(2), ...
                ['高度: ', num2str(actual_height, '%.2f'), ' m'], ...
                'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');

            cropped_image = imcrop(corn_image, rect);

            processing_window = figure('Name', '图像处理过程', ...
                                       'Position', [200, 200, 800, 600], ...
                                       'MenuBar', 'none', ...
                                       'ToolBar', 'none', ...
                                       'NumberTitle', 'off');


% 在图像处理窗口中创建四个图像显示区域
% Original Image Axes
original_axes = axes('Parent', processing_window, 'Position', [0.05, 0.55, 0.4, 0.4]);
imshow(cropped_image, 'Parent', original_axes);
title(original_axes, '裁剪图像');

% Gray Image Axes
filled_image_axes = axes('Parent', processing_window, 'Position', [0.55, 0.55, 0.4, 0.4]);

% Binary Image Axes
 exg_binary_axes = axes('Parent', processing_window, 'Position', [0.05, 0.1, 0.4, 0.4]);

% Edge Image Axes
final_bw_axes = axes('Parent', processing_window, 'Position', [0.55, 0.1, 0.4, 0.4]);

scale_factor = 0.5;
resized_image = imresize(cropped_image, scale_factor);

view_width = 2 * distance * tan(deg2rad(horizontal_fov / 2));
view_height = 2 * distance * tan(deg2rad(vertical_fov / 2));

[resized_height, resized_width, ~] = size(resized_image);
diagonal_pixels = sqrt(resized_width^2 + resized_height^2);
pixel_to_meter = sqrt(view_width^2 * view_height^2) / diagonal_pixels;

% 计算 EXG
exg_image = 2 * cropped_image(:, :, 2) - cropped_image(:, :, 1) - cropped_image(:, :, 3);
level = graythresh(exg_image); % 使用 Otsu 方法获取阈值
exg_binary = imbinarize(exg_image, level); % 二值化 EXG 图像

% 显示 EXG 二值图像
imshow(imresize(exg_binary, scale_factor), 'Parent', exg_binary_axes, 'InitialMagnification', 'fit');
title(exg_binary_axes, 'EXG 二值图像');


% 转换到 HSV 颜色空间提取非绿色叶片
hsv_image = rgb2hsv(cropped_image); % 转换 RGB 图像到 HSV
hue_channel = hsv_image(:, :, 1); % 提取色相通道
saturation_channel = hsv_image(:, :, 2); % 提取饱和度通道

% 定义非绿色的 HSV 范围
non_green_mask = (hue_channel < 0.25 | hue_channel > 0.45) & (saturation_channel > 0.5); % 非绿色范围

% 显示非绿色掩膜
%imshow(non_green_mask, 'Parent', bw_axes, 'InitialMagnification', 'fit');
%title(bw_axes, '非绿色掩膜');
% 结合绿色和黄色的掩膜
combined_mask = exg_binary | non_green_mask; % 结合掩膜

% 开运算去噪声
combined_mask = imopen(combined_mask, strel('disk', 5)); 

% 显示最终的二值图像
%imshow(combined_mask, 'Parent', final_bw_axes, 'InitialMagnification', 'fit');
%title(final_bw_axes, '最终二值图像');

% 进行边缘提取
smooth_image = imgaussfilt(resized_image, 2);
gray_image = rgb2gray(smooth_image);

edge_method = get(edge_method_popup, 'Value');
switch edge_method
    case 1 % Canny
        edges = edge(gray_image, 'Canny');
    case 2 % Sobel
        edges = edge(gray_image, 'Sobel');
    case 3 % Laplacian
        edges = edge(gray_image, 'log'); % Laplacian of Gaussian
end

% 调整边缘图像大小以匹配掩膜
% 检查维度
disp(['edges size: ', num2str(size(edges))]);
disp(['exg_binary size: ', num2str(size(exg_binary))]);

% 调整尺寸以确保一致
% 调整边缘图像大小以匹配掩膜
combined_mask = imresize(combined_mask, size(gray_image));
edges = imresize(edges, size(combined_mask));


% 提取掩膜附近的边缘并填充
filled_image = zeros(size(combined_mask)); % 初始化填充图像

% 找到边缘区域的连通组件
[L, num] = bwlabel(edges); % 连通区域标记

% 对每个连通区域进行填充
for i = 1:num
    % 创建一个掩膜，只包含当前连通区域
    current_region = (L == i);
    
    % 进行填充
    filled_region = imfill(current_region, 'holes'); % 填充内部的孔
    
    % 将填充区域添加到结果图像中
    filled_image = filled_image | filled_region; % 逻辑或操作
end

% 确保填充区域在掩膜附近
filled_image = filled_image & combined_mask; % 只保留掩膜区域内的填充

% 显示边缘图像
imshow(filled_image, 'Parent', filled_image_axes, 'InitialMagnification', 'fit');
title(filled_image_axes, '边缘图像');




% 计算和显示最终的组合图像（边缘与提取区域）
final_combined_image = combined_mask | filled_image; % 结合填充的边缘和掩膜
imshow(final_combined_image, 'Parent', final_bw_axes, 'InitialMagnification', 'fit');
title(final_bw_axes, '边缘与掩膜结合');

% 确保 final_combined_image 不为空
if any(final_combined_image(:))
    % 计算叶面积
    leaf_area = sum(final_combined_image(:)) * (pixel_to_meter^2);
    standardized_LAI = leaf_area / (view_width * view_height);
else
    warning('final_combined_image 为空，无法计算叶面积。');
end
            [G, distances] = calculateGFunction(final_combined_image, pixel_to_meter);

            if numel(distances) ~= numel(G)
                errordlg('G函数计算错误。', '错误', 'modal');
                return;
            end

            axes(g_axes);
            plot(distances, G, 'LineWidth', 2);
            title(g_axes, 'G 函数');
            xlabel(g_axes, '距离 (m)');
            ylabel(g_axes, 'G');

            set(result_text, 'String', ['LAI: ', num2str(standardized_LAI, '%.2f')]);

            disp(['standardized_LAI: ', num2str(standardized_LAI)]);

       % 保存结果到 Excel
        saveResultsToExcel(standardized_LAI, distance, sensor_width, sensor_height, focal_length);
        catch ME
            disp(ME.message);  % 打印错误信息
            errordlg('处理图像时发生错误。', '错误', 'modal');
        end
    end
     % 保存结果到 Excel 的函数
function saveResultsToExcel(lai, distance, sensor_width, sensor_height, focal_length)
    disp('保存结果到 Excel');  % 调试输出
    % 输出文件路径
    output_file_path = 'D:\\桌面\\河大LAI\\LAI_Results.xlsx';
    
    % 创建结果表
    results_table = table(lai, distance, sensor_width, sensor_height, focal_length, ...
                          'VariableNames', {'LAI', 'Distance_m', 'Sensor_Width_mm', 'Sensor_Height_mm', 'Focal_Length_mm'});

    % 检查文件是否存在
    if isfile(output_file_path)
        disp('文件存在，准备更新');  % 调试输出
        % 读取现有数据
        existing_data = readtable(output_file_path, 'Sheet', 'LAI Results');
        % 更新数据
        updated_data = [existing_data; results_table];
        % 写入更新后的数据
        writetable(updated_data, output_file_path, 'Sheet', 'LAI Results', 'WriteRowNames', false, 'FileType', 'spreadsheet');
    else
        disp('文件不存在，创建新文件');  % 调试输出
        % 写入新的结果表
        writetable(results_table, output_file_path, 'Sheet', 'LAI Results', 'WriteRowNames', false, 'FileType', 'spreadsheet');
    end
    
    disp(['LAI 结果已保存到: ', output_file_path]);
end


    % 更新矩形区域的回调函数
   % 更新矩形区域的回调函数
function updateRectInfo(~, ~)
    % 设定矩形的实际大小（以米为单位）
    actual_width_m = 800; % 宽度
    actual_height_m = 800; % 高度

    % 获取输入的参数
    distance = str2double(get(distance_edit, 'String'));
    sensor_width = str2double(get(sensor_width_edit, 'String'));
    sensor_height = str2double(get(sensor_height_edit, 'String'));
    focal_length = str2double(get(focal_length_edit, 'String'));

    % 确保参数有效
    if isnan(distance) || isnan(sensor_width) || isnan(sensor_height) || isnan(focal_length) || ...
       distance <= 0 || sensor_width <= 0 || sensor_height <= 0 || focal_length <= 0
        errordlg('请输入有效的参数值。', '输入错误', 'modal');
        return;
    end

    % 计算像素尺寸
    pixel_to_meter = calculatePixelToMeter(sensor_width, sensor_height, focal_length, distance);
    width_pixels = actual_width_m / pixel_to_meter;
    height_pixels = actual_height_m / pixel_to_meter;

    % 计算矩形的起始位置（居中显示在图片上）
    img_size = size(img_data);
    center_x = img_size(2) / 2;
    center_y = img_size(1) / 2;
    rect_info = [center_x - width_pixels / 2, center_y - height_pixels / 2, width_pixels, height_pixels];

    drawRectangle();
    % 启用鼠标移动
    set(main_window, 'WindowButtonMotionFcn', @moveRectangle);
    set(main_window, 'WindowButtonUpFcn', @stopMovingRectangle);
end
% 绘制矩形
    function drawRectangle()
        cla(image_axes);
        imshow(img_data, 'Parent', image_axes);  
        hold(image_axes, 'on');
        rectangle('Position', rect_info, 'EdgeColor', 'r', 'LineWidth', 2);
        hold(image_axes, 'off');
    end
% 移动矩形
function moveRectangle(~, ~)
    if isempty(rect_info)
        return;
    end
    % 获取当前鼠标位置
    mouse_pos = get(image_axes, 'CurrentPoint');
    mouse_x = mouse_pos(1, 1);
    mouse_y = mouse_pos(1, 2);
    
    % 更新矩形的位置
    new_x = mouse_x - rect_info(3) / 2; % 中心对齐
    new_y = mouse_y - rect_info(4) / 2; % 中心对齐
    rect_info(1:2) = [new_x, new_y];
    
    % 重绘矩形
    drawRectangle();
end

% 停止移动矩形
function stopMovingRectangle(~, ~)
    set(main_window, 'WindowButtonMotionFcn', '');
    set(main_window, 'WindowButtonUpFcn', '');
end
% 计算像素到米的转换因子
function pixel_to_meter = calculatePixelToMeter(sensor_width, sensor_height, focal_length, distance)
    view_width = 2 * distance * tan(deg2rad(calculateFOV(sensor_width, focal_length) / 2));
    view_height = 2 * distance * tan(deg2rad(calculateFOV(sensor_height, focal_length) / 2));
    pixel_to_meter = sqrt(view_width^2 * view_height^2) / sqrt(sensor_width^2 + sensor_height^2);
end


    % 创建图像选择区域的按钮
    select_area_button = uicontrol('Parent', control_panel, 'Style', 'pushbutton', ...
                                   'String', '选择区域', ...
                                   'Position', [360, 50, 100, 30], ...
                                   'Callback', @updateRectInfo);

    % 计算G函数的辅助函数
    function [G, distances] = calculateGFunction(final_combined_image, pixel_to_meter)
        dist_image = bwdist(~final_combined_image);
        dist_hist = histcounts(dist_image(:), 'BinLimits', [0, pixel_to_meter * sqrt(numel(final_combined_image))], 'NumBins', 50);
        G = cumsum(dist_hist) / sum(dist_hist);
        bin_edges = linspace(0, pixel_to_meter * sqrt(numel(final_combined_image)), numel(dist_hist) + 1);
        distances = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;
    end

    % 计算视场角的函数
    function fov = calculateFOV(sensor_dim, focal_length)
        fov = 2 * atan(sensor_dim / (2 * focal_length)) * (180 / pi);
    end
end