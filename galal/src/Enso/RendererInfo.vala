//
//  Copyright (C) 2018 Adam Bieńkowski
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Gala
{
    public enum Vendor
    {
        NVIDIA,
        ATI,
        INTEL,
        QUALCOMM,
        VIRTUAL
    }

    public enum IntelChipset
    {
        I8XX,
        I915,
        I965,
        SandyBridge,
        IvyBridge,
        Haswell,
        UNKNOWN
    }

    public class RendererInfo : Object
    {
        const uint GL_VENDOR = 0x1F00;
        const uint GL_RENDERER = 0x1F01;

        public Vendor vendor { get; construct; default = Vendor.VIRTUAL; }
        public IntelChipset intel_chipset { get; construct; default = IntelChipset.UNKNOWN; }

        delegate unowned string? GlQueryFunc (uint id);
        GlQueryFunc gl_get_string;

        private static RendererInfo instance;
        public static unowned RendererInfo get_default ()
        {
            if (instance == null) {
                instance = new RendererInfo ();
            }

            return instance;
        }

        construct {
            gl_get_string = (GlQueryFunc) Cogl.get_proc_address ("glGetString");
            if (gl_get_string == null) {
                return;
            }

            unowned string? vendor_str = gl_get_string (GL_VENDOR);
            if (vendor_str == null) {
                vendor = Vendor.VIRTUAL;
                return;
            }

            unowned string? renderer_str = gl_get_string (GL_RENDERER);

            if (vendor_str.contains ("NVIDIA Corporation")) {
                vendor = Vendor.NVIDIA;
            } else if (vendor_str.contains ("ATI Technologies Inc.")) {
                vendor = Vendor.ATI;
            } else if (renderer_str != null && renderer_str.contains ("Intel")) {
                vendor = Vendor.INTEL;
                intel_chipset = parse_intel_chipset (renderer_str);
            } else if (vendor_str.contains ("Qualcomm")) {
                vendor = Vendor.QUALCOMM;
            } else {
                vendor = Vendor.VIRTUAL;
            }
        }

        IntelChipset parse_intel_chipset (string renderer)
        {
            if (renderer.contains ("845G") ||
                renderer.contains ("830M") ||
                renderer.contains ("852GM/855GM") ||
                renderer.contains ("865G")) {
                return IntelChipset.I8XX;
            }

            if (renderer.contains ("915G") ||
                renderer.contains ("E7221G") ||
                renderer.contains ("915GM") ||
                renderer.contains ("945G") ||
                renderer.contains ("945GM") ||
                renderer.contains ("945GME") ||
                renderer.contains ("Q33") ||
                renderer.contains ("Q35") ||
                renderer.contains ("G33") ||
                renderer.contains ("965Q") ||
                renderer.contains ("946GZ") ||
                renderer.contains ("Intel(R) Integrated Graphics Device")) {
                return IntelChipset.I915;
            }

            if (renderer.contains ("965G") ||
                renderer.contains ("G45/G43") ||
                renderer.contains ("965GM") ||
                renderer.contains ("965GME/GLE") ||
                renderer.contains ("GM45") ||
                renderer.contains ("Q45/Q43") ||
                renderer.contains ("G41") ||
                renderer.contains ("B43") ||
                renderer.contains ("Ironlake")) {
                return IntelChipset.I965;
            }

            if (renderer.contains ("Sandybridge")) {
                return IntelChipset.SandyBridge;
            }

            if (renderer.contains ("Ivybridge")) {
                return IntelChipset.IvyBridge;
            }

            if (renderer.contains ("Haswell")) {
                return IntelChipset.Haswell;
            }

            return IntelChipset.UNKNOWN;
        }
    }
}
