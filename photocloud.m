% user input parameters
path_to_data = 'C:/working/test';
control_file = 'control.txt';

f_pix = 7788;  % calibrated focal length [units: pixels]
water_elevation = 190;
downsample_coefficient = 0.02;

% import airborne control from Metashape as a table
% 3D position must all be in same units (e.g. meters)
% Attitude must be yaw, pitch, roll (in degrees)
EOP = readtable(control_file, 'HeaderLines', 1);

% get a struct of all filenames in path that end in '.jpg'
img_files = dir(fullfile(path_to_data, '*.jpg'));

% iterate through each filename to send to solver
for kk = 1:length(img_files)

    % grab one image at a time
    img_name = img_files(kk).name;

    % solve for points, write to file
    imageToPoints(img_name, downsample_coefficient, f_pix, EOP, water_elevation)

end


function imageToPoints(image_name, resize_coeff, focal_length, control_table, plane_elev)
%IMAGETOPOINTS 

    % initial rotation and resize
    image_in = imread(image_name);
    image_in = imresize(image_in, resize_coeff);
    image_in = imrotate(image_in, -90);  % initial alignment w/ IMU frame

    % input image dimensions for interation and coordinate conversion
    format_rows = size(image_in, 1);
    format_columns = size(image_in, 2);
    
    % find control info for current image
    control = control_table(strcmp(control_table.x_Label, image_name), :);

    % rotation matrix for image
    R_yaw = makehgtform('zrotate', deg2rad(-control.Yaw));  % yaw is clockwise therefore negative
    R_pitch = makehgtform('xrotate', deg2rad(control.Pitch));
    R_roll = makehgtform('yrotate', deg2rad(control.Roll));

    rot = R_roll * R_pitch * R_yaw;  % active rotation
    rot = rot(1:3, 1:3);

    % open output file and leave open for appending
    fileID = fopen('out.txt', 'a');

    % we iterate over each cell of the resized image...
    for ii = 1:format_rows

        % convert row number to x-coordinate
        x_row = ii - format_rows / 2;
    
        for jj = 1:format_columns

            % convert column number to y-coordinate
            y_col = format_columns / 2 - jj;

            % the direction of the line through the pixel as a vector
            pixel_dir = [x_row/resize_coeff; y_col/resize_coeff; -focal_length];
            pixel_dir = rot * pixel_dir;

            % homogeneous solver
            exposure_station = [
                control.X_Easting;
                control.Y_Northing;
                control.Z_Altitude
            ];
            pt = horizontalPlaneMeet(pixel_dir, exposure_station, plane_elev);

            % digital numbers of pixel
            DN = squeeze(image_in(ii, jj, :));

            % print coordinates and digital numbers
            fprintf(fileID, '%.1f %.1f %.1f %d %d %d\n', pt, DN);

        end
    end

    % close output file
    fclose(fileID);
end


function pt = horizontalPlaneMeet(line_dir, line_pt, plane_elevation)
    %HORIZONTALPLANEMEET Solve line-plane intersection in a special case.
    %   X = HORIZONTALPLANEMEET finds a point vector where a line
    %   intersects a horizontal plane using the homogeneous meet operator.
    %
    %   Inputs:
    %              line_dir: 3 x 1 vector of line direction
    %               line_pt: 3 x 1 vector of point on line
    %       plane_elevation: scalar; elevation of horizontal plane

    % variable shortened for ease of use
    h = plane_elevation;
    
    % meet operator matrix for special case where the plane normal is 
    % (0, 0, 1) at a known z-coordinate of h
    Wx = [ ...
        h 0 0 0 -1 0; ...
        0 h 0 1 0 0; ...
        0 0 h 0 0 0; ...
        0 0 1 0 0 0; ...
    ];

    % the moment of a line described by a direction and a point is the
    % cross vector between the direction vector and point vector.
    moment = cross(line_pt, line_dir);
    L = [line_dir; moment];

    % the homogeneous point P is the product of Wx and L
    P = Wx * L;
    pt = P(1:3) / P(4);
end
