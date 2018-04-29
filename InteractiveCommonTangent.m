function InteractiveCommonTangent
tolerance = 0.001;
color = 'b';
style = '--';
width = 0.5;
 
circleCount = 1;
buttonDown = 0;
x1 = [0 0]; y1 = [0 0]; x2 = [0 0]; y2 = [0 0];
 
figure('WindowButtonDownFcn', @getBeginPoint, ...
    'WindowButtonMotionFcn', @updateCircle, ...
    'WindowButtonUpFcn', @getEndPoint);
ah = axes('SortMethod', 'childorder');
circles = [rectangle('Position', [0 0 0 0], 'Curvature', 1), ...
    rectangle('Position', [0 0 0 0], 'Curvature', 1)];
hold on;
axis equal;
grid on;
axis ([0 1 0 1]);
 
    function getBeginPoint(src, ~)
        if strcmp(get(src, 'SelectionType'), 'normal')
            buttonDown = 1;
            [x1(circleCount), y1(circleCount)] = get_point(ah);
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
            [x, y] = get_point(ah);
            x0 = x1(circleCount);
            y0 = y1(circleCount);
            xx = (x + x0) / 2;
            yy = (y + y0) / 2;
            r = norm([x-x0, y-y0]) / 2;
            set(circles(circleCount), 'Position', [xx-r yy-r 2*r 2*r]);
            axis ([0 1 0 1]);
        end
    end
 
    function getEndPoint(~, ~)
        buttonDown = 0;
        [x2(circleCount), y2(circleCount)] = get_point(ah);
        circleCount = circleCount + 1;
        if circleCount > 2
            rawData = [x1' y1' x2' y2'];
            drawCommonTangent(rawData);
            axis ([0 1 0 1]);
            circleCount = 1;
        end
    end
 
    function [x, y] = get_point(ah)
        cp = get(ah, 'CurrentPoint');
        x = cp(1,1);
        y = cp(1,2);
    end
 
    function drawCommonTangent(rawCircles)
        r1 = norm(rawCircles(1, 3:4) - rawCircles(1, 1:2)) / 2;
        r2 = norm(rawCircles(2, 3:4) - rawCircles(2, 1:2)) / 2;
        if (r1 <= tolerance || r2 <= tolerance)
            set(circles, 'Position', [0 0 0 0]);
            return;
        end
        % make r1 >= r2
        if (r1 < r2)
            rawCircles = flip(rawCircles);
            [r2, r1] = deal(r1, r2);
        end
        
        xx1 = (rawCircles(1,1) + rawCircles(1,3)) / 2;
        yy1 = (rawCircles(1,2) + rawCircles(1,4)) / 2;
        xx2 = (rawCircles(2,1) + rawCircles(2,3)) / 2;
        yy2 = (rawCircles(2,2) + rawCircles(2,4)) / 2;
        vX = [xx1 xx2];
        vY = [yy1 yy2];
        d = norm([xx2-xx1, yy2-yy1]);
        unitTangent = [xx2-xx1, yy2-yy1] / d;
        unitNormal = [yy1-yy2, xx2-xx1] / d;
        
        set(circles(1), 'Position', [xx1-r1 yy1-r1 2*r1 2*r1]);
        set(circles(2), 'Position', [xx2-r2 yy2-r2 2*r2 2*r2]);
        
        if (abs(r1-r2) <= tolerance ...
                && abs(xx1-xx2) <= tolerance ...
                && abs(yy1-yy2) <= tolerance)
            % I didn't have much education. Don't try to fool me.
            text(xx1, yy1, 'THIS MAKES NO SENSE!', ...
                'HorizontalAlignment', 'center');
            
        else
            % Internal Common Tangents
            if (d + tolerance >= r1 + r2)
                if (d - tolerance <= r1 + r2)
                    center = deal([xx1 yy1] + unitTangent * r1);
                    theta = pi/2;
                    makeTransformedLine(vX, vY, center, theta, 3 * r1);
                else
                    D = min(realmax, d * r1/(r1+r2));
                    center = deal([xx1 yy1] + unitTangent * D);
                    theta = asin((r1+r2)/d);
                    makeTransformedLine(vX, vY, center, theta, 3 * D);
                    makeTransformedLine(vX, vY, center, -theta, 3 * D);
                end
            end
            
            % External Common Tangents
            if (d + tolerance >= r1 - r2)
                if (r1 - r2 <= tolerance)
                    [X1, Y1] = deal([xx1 yy1] - unitTangent * d);
                    [X2, Y2] = deal([xx2 yy2] + unitTangent * d);
                    delta = unitNormal * r1;
                    line([X1, X2] + delta(1), [Y1, Y2] + delta(2), ...
                        'Color', color, ...
                        'LineStyle', style, ...
                        'LineWidth', width);
                    line([X1, X2] - delta(1), [Y1, Y2] - delta(2), ...
                        'Color', color, ...
                        'LineStyle', style, ...
                        'LineWidth', width);
                elseif (d - tolerance <= r1 - r2)
                    center = deal([xx1 yy1] + unitTangent * r1);
                    theta = pi/2;
                    makeTransformedLine(vX, vY, center, theta, 3 * r1);
                else
                    D = min(realmax, d * r1/(r1-r2));
                    center = deal([xx1 yy1] + unitTangent * D);
                    theta = asin((r1-r2)/d);
                    makeTransformedLine(vX, vY, center, theta, 3 * D);
                    makeTransformedLine(vX, vY, center, -theta, 3 * D);
                end
            end
        end
    end
 
    function makeTransformedLine(vX, vY, center, theta, length)
        oldLength = norm([vX(2)-vX(1), vY(2)-vY(1)]);
        scale = min(realmax, length / oldLength);
        lineCenter = [mean(vX), mean(vY)];
        
        ht = hgtransform;
        line(vX, vY, 'Parent', ht, ...
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
