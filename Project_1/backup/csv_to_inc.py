# INPUT:
#   mountain.inc
#       this is an empty file
#
#   mountain.csv
#       you may use excel to generate your csv file
#       it formate is like that:
#       1,2,3,4
#       5,6,7,8
#       9,0,5,9
#       1,3,4,5
#       the first line is the serial number, and will be droped
#
# OUTPUT:
#       after run this python file, mountain.csv will become:
#       .db  5, 6, 7, 8
#       .db  9, 0, 5, 9
#       .db  1, 3, 4, 5

import csv
grid = []

file_name = input('please input the csv file name, you don\'t need the extension name: ')

with open(file_name+'.csv', 'r') as csv_file:
    csv_table = csv.reader(csv_file)
    for line in csv_table:
        grid.append(line)


with open(file_name+'.inc', 'w') as inc_file:
    for line in grid[1:]:
        inc_file.writelines('.db  ')
        inc_file.writelines(str(line[0]))
        inc_file.writelines(', ' + str(x) for x in line[1:])
        inc_file.writelines('\n')