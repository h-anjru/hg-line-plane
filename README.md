# hg-line-plane
Create a georeferenced point cloud from a photograph over an assumed horizontal surface.

## Overview
The tool developed here projects pixels from an image with known exterior orientation onto an objective plane of known elevation. If the focal length, format size, and the exterior orientation for a given photograph are known, then each pixel of that photograph can be represented as a line in real-world coordinates. This line passes from the perspective center of the camera through the pixel. The intersection of this line with an assumed horizontal plane can then be determined.

## Determining the elevation of the water surface
The surface of a body of water for a local area can be assumed to be horizontal. The elevation $h$ of the surface can be determined, among other means, from SfM reconstruction of the scene through inspection of the reconstructed point cloud and photographic evidence.

## Determining the pixel line
First, an image coordinate system is defined with the objective lens at the origin. The image plane is defined as horizontal at negative focal length, $-f$. 

Row and column coordinates from an image are converted to $(x,y)$ with the origin at the principal point. A light ray from object space passing thru the image plane to the objective lens is represented as a line with direction $\vec{l'}=\langle x,y,-f \rangle$. This vector need not be normalized, nor is its directionality important, so long as the units are consistent. The simplest approach may be to use the units of pixels for ease of determining $x$ and $y$. Row and column coordinates—left-handed coordinates with an origin at the top left of the photograph’s format—can be converted to a right-hand $(x,y)$ coordinate pair with its origin at the center of the format as such:

$x=\text{row number}-\frac{\text{(number of rows)}}{2}$

$y=\text{column number}+\frac{\text{(number of columns)}}{2}$

The focal length of a camera can be converted to pixels if the camera’s pixel pitch (i.e., the dimensions of each pixel) is known. The focal length in pixels is also a common output of many SfM software applications.

The true direction of $\vec{l'}$ can be found by applying to it an active rotation as defined by the camera's exterior orientation. The rotation matrix $R$ by convention is a passive rotiation; the active rotation is $R^T$. The direction of $\vec{l'}$ in object space is thus given by $l=R^T\vec{l'}$.

## Homogeneous line-plane intersection
A line with direction $\vec{d}$ passing through a point $\vec{x}$ is represented homogeneously by six coordinates that describe its direction and moment, called Plucker coordinates: $L=(\vec{d};\vec{m})$ where $\vec{m}=\vec{d} \times \vec{x}$.

A plane with normal $\vec{n}$ passing through a point $r$ is represented homogeneously as $W=(\vec{n};ϵ)$ where $ϵ=-\vec{r} \cdot \vec{n}$.

The homogeneous point $P$ where $L$ intersects $W$ is found by 

$P=W_ \times L$   where    
```math
W_×=\begin{bmatrix} 𝜖𝟏 &\vec{n}_× \\ \vec{n}^T & 0 \end{bmatrix}
```

$n_×$ being the cross product matrix operator, a skew-symmetric matrix.

For the special case where the objective plane is horizontal with a known elevation $h$ (i.e., $z=h$),

$W_×=\begin{bmatrix}
    h & 0 & 0 & 0 & -1 & 0 \\\
    0 & h & 0 & 1 & 0 & 0 \\\
    0 & 0 & h & 0 & 0 & 0 \\\
    0 & 0 & 1 & 0 & 0 & 0
\end{bmatrix}$ 

## Creating a georeferenced point cloud
This tool can generate a set of 3D points, but those points will not be recognized as georeferenced by geospatial software without the appending of metadata about the data’s coordinate system. LASTools, for example, could be used to append the proper metadata to the generated point cloud, including horizontal datum and projection, vertical datum, and units (e.g. meters).
