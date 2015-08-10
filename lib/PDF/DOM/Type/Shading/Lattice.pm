use v6;

use PDF::DOM::Type::Shading;

#| /ShadingType 5 - Lattice

class PDF::DOM::Type::Shading::Lattice
    is PDF::DOM::Type::Shading {
    use PDF::Object::Tie;
    # see [PDF 1.7 TABLE 4.33 Additional entries specific to a type 5 shading dictionary]
    has Int $.BitsPerCoordinate is entry(:required); #| (Required) The number of bits used to represent each vertex coordinate. Valid values are 1, 2, 4, 8, 12, 16, 24, and 32.
    has Int $.BitsPerComponent is entry(:required);  #| (Required) The number of bits used to represent each color component. Valid values are 1, 2, 4, 8, 12, and 16.
    has Int $.VerticesPerRow is entry(:required);    #| (Required) The number of vertices in each row of the lattice; the value must be greater than or equal to 2.
    has Array $.Decode is entry(:required);          #| (Required) An array of numbers specifying how to map vertex coordinates and color components into the appropriate ranges of values
    has $.Function is entry;                         #| (Optional) A 1-in, n-out function or an array of n 1-in, 1-out functions (where n is the number of color components in the shading dictionary’s color space).
}