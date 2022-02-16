
# using Pkg
# Pkg.activate(".")
# Pkg.instantiate() # only run first time to download packages

@info "start loading packages"

using Dash
using PlotlyBase
using DataFrames
using XLSX
using CSV
using JSON
using Statistics
using Colors
using Dates
using Tar
using Base64

@info "include functions"

@info "initialize app"
app = dash(external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"],
    suppress_callback_exceptions = false)

@info "app layout"
app.layout = html_div() do
    html_h2("Analysis"),
    html_br(),
    dcc_loading([
        html_button("Run analysis", id = "button2"),
        dcc_download(id = "download-results")
    ]),
    html_br(),
    dcc_graph(id = "graph1")
end

callback!(app,
    Output("upload-filename", "children"),
    Output("store_data", "data"),
    Input("upload-data", "filename"),
    Input("upload-data", "contents"),
    prevent_initial_call = true
) do uploaded_filename, uploaded_file_contents

    # write xlsx content into a xlsx file local to the app
    content_start = findfirst(";base64,", uploaded_file_contents)[end] + 1
    raw = base64decode(uploaded_file_contents[content_start:end])
    open(uploaded_filename, "w") do io
        write(io, raw)
    end

    df = read_raw_data(uploaded_filename)

    return string(uploaded_filename), JSON.json(df)
end

# run full analysis
callback!(app,
    Output("download-results", "data"),
    # Output("results", "children"),
    Input("button2", "n_clicks")
) do clicked

    # directory to store results
    SAVE_PATH = tempdir() * "/results_" * Dates.format(now(), "yyyy_mm_dd_HH_MM_SS") * "/"
    @info "Results path" SAVE_PATH
    
    # create directory
    mkpath(SAVE_PATH)

    # create data
    df = DataFrame(a = rand(5), b = rand(5))

    # save DataFrame
    CSV.write(joinpath(SAVE_PATH, "df.csv"), df)
    # CSV.write(joinpath("df.csv"), df)

    # create zip results
    tarball = Tar.create(SAVE_PATH)
    content_raw = open(tarball) do file
        read(file)
    end
    content_base64 = base64encode(content_raw)

    sleep(30)

    return Dict(:filename => "results.tar", :content => content_base64)

end # do

@info "launching app"
# port = haskey(ENV, "PORT") ? parse(Int64, ENV["PORT"]) : 8050
run_server(app, "0.0.0.0", 8050, debug = false)
