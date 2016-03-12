"Definitions specific to VNAs."
module VNA
import PainterQB: InstrumentProperty, InstrumentVISA, TransferFormat

include(joinpath(Pkg.dir("PainterQB"),"src/meta/Properties.jl"))

export InstrumentVNA, Format, Parameter
export clearavg, data

"Assume that all VNAs support VISA."
abstract InstrumentVNA  <: InstrumentVISA

"Post-processing and display formats typical of VNAs."
abstract Format         <: InstrumentProperty

"VNA measurement parameter, e.g. S11, S12, etc."
abstract Parameter      <: InstrumentProperty
abstract SParameter     <: Parameter
abstract ABCDParameter  <: Parameter

subtypesArray = [
    # True formatting types
    # Format refers to e.g. log magnitude, phase, Smith chart, etc.
    (:LogMagnitude,             Format),
    (:Phase,                    Format),
    (:GroupDelay,               Format),
    (:SmithLinear,              Format),
    (:SmithLog,                 Format),
    (:SmithComplex,             Format),
    (:Smith,                    Format),
    (:SmithAdmittance,          Format),
    (:PolarLinear,              Format),
    (:PolarLog,                 Format),
    (:PolarComplex,             Format),
    (:LinearMagnitude,          Format),
    (:SWR,                      Format),
    (:RealPart,                 Format),
    (:ImagPart,                 Format),
    (:ExpandedPhase,            Format),
    (:PositivePhase,            Format),

    # From high-level to low-level...
    # These formats should just be complex numbers at various levels of processing.
    # Mathematics: Fully calibrated data, including trace mathematics.
    # Calibrated:  Fully calibrated data.
    # Factory:     Factory calibrated data.
    # Raw:         Uncorrected data in the most raw form possible for a given VNA.
    (:Mathematics,              Format),
    (:Calibrated,               Format),
    (:Factory,                  Format),
    (:Raw,                      Format),

    (:S11,                      SParameter),
    (:S12,                      SParameter),
    (:S21,                      SParameter),
    (:S22,                      SParameter),
]

for (subtypeSymb,supertype) in subtypesArray
    generate_properties(subtypeSymb, supertype, false)
end

"Read the data from the VNA."
function data end

"""
SENSe#:AVERage:CLEar
[E5071C][http://ena.support.keysight.com/e5071c/manuals/webhelp/eng/programming/command_reference/sense/scpi_sense_ch_average_clear.htm]
[ZNB20][https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_6/Content/ff10e010f00d4b14.htm#ID_f98b8f87fa95f4f10a00206a01537005-1a87cdf1fa95ef340a00206a01a6673d-en-US]

Restart averaging for a given channel `ch` (defaults to 1).
"""
function clearavg(ins::InstrumentVNA, ch::Integer=1)
    write(ins, ":SENS#:AVER:CLE", ch)
end

"Fallback method assumes we cannot do what is requested."
datacmd{T<:Format}(x::InstrumentVNA, ::Type{T}) = error("Not supported for this VNA.")

end
