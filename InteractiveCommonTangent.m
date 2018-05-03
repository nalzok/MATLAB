function InteractiveCommonTangent
tolerance = 0.001;
color = 'b';
style = '--';
width = 0.5;

circleCount = 1;
buttonDown = 0;
figure('WindowButtonDownFcn', @getBeginPoint, ...
    'WindowButtonMotionFcn', @updateCircle, ...
    'WindowButtonUpFcn', @getEndPoint);
ah = axes('SortMethod', 'childorder');
[circleEdge1, circleEdge2] = deal(zeros(2, 2));
circles = [rectangle('Position', [0 0 0 0], 'Curvature', 1), ...
    rectangle('Position', [0 0 0 0], 'Curvature', 1)];
hold on;
grid on;
grid minor;
axis equal;
axis ([0 1 0 1]);

    function getBeginPoint(src, ~)
        if strcmp(get(src, 'SelectionType'), 'normal')
            buttonDown = 1;
            circleEdge1(circleCount, :) = get_point(ah);
            if circleCount == 1
                assets = findobj('Type', 'Line', ...
                    '-or', 'Type', 'Transform', ...
                    '-or', 'Type', 'Text');
                delete(assets);
                set(circles, 'Position', [0 0 0 0]);
            end
        end
    end

    function updateCircle(~, ~)
        if buttonDown
            pt1 = circleEdge1(circleCount, :);
            pt2 = get_point(ah);
            center = (pt1 + pt2) / 2;
            d = norm(pt1 - pt2);
            set(circles(circleCount), ...
                'Position', [center-d/2, d, d]);
            axis ([0 1 0 1]);
        end
    end

    function getEndPoint(~, ~)
        buttonDown = 0;
        circleEdge2(circleCount, :) = get_point(ah);
        circleCount = circleCount + 1;
        if circleCount > 2
            drawCommonTangent([circleEdge1 circleEdge2]);
            axis ([0 1 0 1]);
            circleCount = 1;
        end
    end

    function p = get_point(ah)
        cp = get(ah, 'CurrentPoint');
        p = cp(1, 1:2);
    end

    function drawCommonTangent(rawCircles)
        diamaters = rawCircles(:, 3:4) - rawCircles(:, 1:2);
        r = hypot(diamaters(:, 1), diamaters(:, 2)) / 2;
        if (r(1) <= tolerance || r(2) <= tolerance)
            set(circles, 'Position', [0 0 0 0]);
            return;
        end
        % make r(1) >= r(2)
        if (r(1) < r(2))
            rawCircles = flip(rawCircles);
            r = flip(r);
        end
        
        centers = zeros(2, 2);
        centers(:, 1) = (rawCircles(:, 1) + rawCircles(:, 3)) / 2;  % x
        centers(:, 2) = (rawCircles(:, 2) + rawCircles(:, 4)) / 2;  % y
        
        ctrCtr = centers(2, :) - centers(1, :);
        centerDist = norm(ctrCtr);
        unitTangent = ctrCtr / centerDist;
        unitNormal = [unitTangent(2) -unitTangent(1)];
        
        set(circles(1), 'Position', [centers(1, :)-r(1) 2*r(1) 2*r(1)]);
        set(circles(2), 'Position', [centers(2, :)-r(2) 2*r(2) 2*r(2)]);
        
        if (norm(centers(1, :)-centers(2, :)) <= tolerance ...
                && r(1)-r(2) <= tolerance)
            text(0.5, 0.5, ...
                {'I didn''t have much education.', ...
                'Don''t try to fool me.'}, ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 16);
            return;
        end
        
        % External Common Tangents
        if (centerDist + tolerance >= r(1) - r(2))
            if (r(1) - r(2) <= tolerance)
                farCenters = centers + [-unitTangent; unitTangent] * 0.5;
                shifter = unitNormal * r(1);
                line1 = farCenters + repmat(shifter, 2, 1);
                line(line1(:, 1), line1(:, 2), ...
                    'Color', color, ...
                    'LineStyle', style, ...
                    'LineWidth', width);
                line2 = farCenters - repmat(shifter, 2, 1);
                line(line2(:, 1), line2(:, 2), ...
                    'Color', color, ...
                    'LineStyle', style, ...
                    'LineWidth', width);
            elseif (centerDist - tolerance <= r(1) - r(2))
                center = centers(1, :) + unitTangent * r(1);
                theta = pi/2;
                makeTransformedLine(ctrCtr, center, theta, 3 * r(1));
            else
                D = min(realmax, centerDist * r(1)/(r(1)-r(2)));
                center = centers(1, :) + unitTangent * D;
                theta = asin((r(1)-r(2))/centerDist);
                makeTransformedLine(ctrCtr, center, theta, 3 * D);
                makeTransformedLine(ctrCtr, center, -theta, 3 * D);
            end
        end
        
        % Internal Common Tangents
        if (centerDist + tolerance >= r(1) + r(2))
            if (centerDist - tolerance <= r(1) + r(2))
                center = centers(1, :) + unitTangent * r(1);
                theta = pi/2;
                makeTransformedLine(ctrCtr, center, theta, 3 * r(1));
            else
                D = min(realmax, centerDist * r(1)/(r(1)+r(2)));
                center = centers(1, :) + unitTangent * D;
                theta = asin((r(1)+r(2))/centerDist);
                makeTransformedLine(ctrCtr, center, theta, 3 * D);
                makeTransformedLine(ctrCtr, center, -theta, 3 * D);
            end
        end
    end

    function makeTransformedLine(dirVector, center, theta, len)
        oldLen = norm(dirVector);
        scale = min(realmax, len / oldLen);
        lineCenter = dirVector / 2;
        
        ht = hgtransform;
        line([0 dirVector(1)], [0 dirVector(2)], ...
            'Parent', ht, ...
            'Color', color, ...
            'LineStyle', style, ...
            'LineWidth', width);
        
        N = makehgtform('translate', -[lineCenter 0]);
        R = makehgtform('zrotate', theta);
        S = makehgtform('scale', scale);
        T = makehgtform('translate', [center 0]);
        
        set(ht, 'Matrix', T*S*R*N);
    end
end
