
def make_webmo_list(group_name, csv_file_path):
    """
    create a .webmo file with the information needed to "import" a class
    group_name: the name of the group for that class usually CHEM####-{f/s}YEAR
    **Note** the group must be created in the group manager util before importing the file.
    It also must have the same name as the group_name argument or the file won't work.
    It is very picky with these imports!!
    """
    output_lines = []
    output_lines.append(",".join(['username','password','group']))
    csv_fh = open(csv_file_path, 'r')
    csv_data = csv_fh.readlines()
    csv_fh.close()
    mode = csv_data[0].strip()
    if(mode == "Email"):
        for line in csv_data[1:]:
            pid = line.strip().split("@")[0]
            output_lines.append(",".join([pid,pid,group_name]))
    if (mode == "PID"):
        for line in csv_data[1:]:
            pid = line.strip()
            output_lines.append(",".join([pid,pid,group_name]))
    with open("{}.webmo".format(group_name),'w') as webmoF:
        webmoF.write("\n".join(output_lines))

if __name__ == "__main__":
    import sys
    make_webmo_list(*sys.argv[1::])
