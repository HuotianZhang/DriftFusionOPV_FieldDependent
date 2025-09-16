% Assume your struct array is named 'data' and has fields 'x' and 'y'
% with dimensions 1x15
% Example: data(1).x, data(1).y, data(2).x, data(2).y, ..., data(15).x, data(15).y

% Initialize a figure
figure;
hold on; % To plot all (x, y) on the same figure

data = result_struct;
% Loop through each element of the struct and plot (x, y)
for i = 3:3
    h_lines = plot(data(i).VV, data(i).JJ); % Use 'o-' for markers and lines, can be customized
    set(h_lines, ...
    'LineWidth', 2.5, ...     % Thicker line
    'LineStyle', '-');        % Solid line

end
ylim([-30, 0]);
xlim([0 1.2]);
% Label axes
xlabel('Applied voltage [V]');
ylabel('Current density [mA/cm^2]');

deltaG_values = 0.00:0.05:0.45;
legend_entries = cell(1, length(deltaG_values)); % Cell array to hold strings
for i = 1:length(deltaG_values)
    legend_entries{i} = sprintf('\\DeltaG = %.2f', deltaG_values(i));
end

legend(legend_entries);

hold off;
