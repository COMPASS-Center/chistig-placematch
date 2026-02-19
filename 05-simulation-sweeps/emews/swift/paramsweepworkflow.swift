import io;
import sys;
import files;
import string;
import emews;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");

file model_sh = input(emews_root+"/scripts/run_chistig_paramsweepworkflow.sh");
file upf = input(argv("f"));

// app function used to run the model
app (file out, file err) run_model(file shfile, string param_line, string instance)
{
    "bash" shfile param_line emews_root instance @stdout=out @stderr=err;
}


// call this to create any required directories
app (void o) make_dir(string dirname) {
    "mkdir" "-p" dirname;
}

// Anything that needs to be done prior to a model
// run (e.g. file creation) should be done within this
// function.
// app (void o) run_prerequisites() {
//
// }

// Iterate over each line in the upf file, passing each line 
// to the model script to run
main() {
    // run_prerequisites() => {
    string upf_lines[] = file_lines(upf);
    foreach s,i in upf_lines {
        string instance = "%s/instance_%i/" % (turbine_output, i+1);
        make_dir(instance) => {
            file out <instance+"out.txt">;
            file err <instance+"err.txt">;
            (out,err) = run_model(model_sh, s, instance);
        }
    }
    // }
}
