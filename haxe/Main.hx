/*
  AOBench (haxe version)
  2012/6/2
  ported by Twitter:@yoshihiro503
	
  aobench site: http://code.google.com/p/aobench/
	
  This code is public domain.
*/

class Vec3 {
    public var x : Float;
    public var y : Float;
    public var z : Float;

    public function new(x, y, z)
        {
            this.x = x;
            this.y = y;
            this.z = z;
    }
    
    public static inline function vadd(a, b)
    {
        return new Vec3(a.x + b.x, a.y + b.y, a.z + b.z);
    }

    public static inline function vsub(a : Vec3, b : Vec3 )
    {
        return new Vec3(a.x - b.x, a.y - b.y, a.z - b.z);
    }

    public static inline function vcross(a:Vec3, b:Vec3)
    {
        return new Vec3(a.y * b.z - a.z * b.y,
                        a.z * b.x - a.x * b.z,
                        a.x * b.y - a.y * b.x);
    }

    public static inline function vdot(a:Vec3, b:Vec3)
    {
        return (a.x * b.x + a.y * b.y + a.z * b.z);
    }

    static inline function vlength(a:Vec3)
    {
        return Math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
    }

    public static function vnormalize(a:Vec3)
    {
        var len = Vec3.vlength(a);
        var v = new Vec3(a.x, a.y, a.z);

        if (Math.abs(len) > 1.0e-17) {
            v.x /= len;
            v.y /= len;
            v.z /= len;
        }

        return v;
    }

} // class Vec3


class Isect {
    public var t : Float;//  = 1000000.0;     // far away
    public var hit :Bool;// = false;
    public var p:Vec3;
    public var n:Vec3;
    public function new() {
        this.p = new Vec3(0.0, 0.0, 0.0);
        this.n = new Vec3(0.0, 0.0, 0.0);
        t = 1000000.0;
        hit = false;
    }
} // Isect


class Ray {
    public var org : Vec3;
    public var dir : Vec3;
    public function new(org, dir) {
        this.org = org;
        this.dir = dir;
    }
} // Ray

class Sphere {
    public var center : Vec3;
    public var radius : Float;

    public function new(center, radius) {
        this.center = center;
        this.radius = radius;
    }
    public function intersect(ray:Ray, isect:Isect) {
        // rs = ray.org - sphere.center
        var rs : Vec3  = Vec3.vsub(ray.org, this.center);
        var B  : Float = Vec3.vdot(rs, ray.dir);
        var C  : Float = Vec3.vdot(rs, rs) - (this.radius * this.radius);
        var D  : Float = B * B - C;

        if (D > 0.0) {
            var t = -B - Math.sqrt(D);

            if ( (t > 0.0) && (t < isect.t) ) {
                isect.t   = t;
                isect.hit = true;

                isect.p = new Vec3(ray.org.x + ray.dir.x * t,
                                   ray.org.y + ray.dir.y * t,
                                   ray.org.z + ray.dir.z * t);

                // calculate normal.
                var n = Vec3.vsub(isect.p, this.center);
                isect.n = Vec3.vnormalize(n);
            }
        }
    }
} // Sphere

class Plane {
    public var p : Vec3;
    public var n : Vec3;
    
    public function new(p, n) {
        this.p = p;
        this.n = n;
    }
    public function intersect (ray:Ray, isect:Isect) {
        var d  = -Vec3.vdot(this.p, this.n);
        var v =  Vec3.vdot(ray.dir, this.n);
        if (Math.abs(v) < 1.0e-17) return;      // no hit
        var t = -(Vec3.vdot(ray.org, this.n) + d) / v;
        if ( (t > 0.0) && (t < isect.t) ) {
            isect.hit = true;
            isect.t   = t;
            isect.n   = this.n;
            isect.p   = new Vec3(ray.org.x + t * ray.dir.x,
                                 ray.org.y + t * ray.dir.y,
                                 ray.org.z + t * ray.dir.z );
        }
    }
} // Plane


class AOBench {
    public function new() {
        spheres = [
                   new Sphere(new Vec3(-2.0, 0.0, -3.5), 0.5),
                   new Sphere(new Vec3(-0.5, 0.0, -3.0), 0.5),
                   new Sphere(new Vec3(1.0, 0.0, -2.2), 0.5)
                   ];
        plane = new Plane(new Vec3(0.0, -0.5, 0.0), new Vec3(0.0, 1.0, 0.0));
    }
	
    static inline var IMAGE_WIDTH  = 256;
    static inline var IMAGE_HEIGHT = 256;
    static inline var NSUBSAMPLES  = 2;
    static inline var NAO_SAMPLES  = 8;
    static inline var EPS          = 0.0001;
    static inline var NPHI   = AOBench.NAO_SAMPLES;
    static inline var NTHETA = AOBench.NAO_SAMPLES;
    static inline var ALLRAY = AOBench.NAO_SAMPLES * AOBench.NAO_SAMPLES;
	
    function clamp(f) : Float
    {
        var i : Float = f * 255.0;
        if (i > 255.0) i = 255.0;
        if (i < 0.0)   i = 0.0;
        return Math.round(i);
    }

    function orthoBasis(basis : Array<Vec3>, n:Vec3) 
    {
        basis[2] = n;
        basis[1] = new Vec3(0.0, 0.0, 0.0);

        if ((n.x < 0.6) && (n.x > -0.6)) {
            basis[1].x = 1.0;
        } else if ((n.y < 0.6) && (n.y > -0.6)) {
            basis[1].y = 1.0;
        } else if ((n.z < 0.6) && (n.z > -0.6)) {
            basis[1].z = 1.0;
        } else {
            basis[1].x = 1.0;
        }

        basis[0] = Vec3.vcross(basis[1], basis[2]);
        basis[0] = Vec3.vnormalize(basis[0]);

        basis[1] = Vec3.vcross(basis[2], basis[0]);
        basis[1] = Vec3.vnormalize(basis[1]);
    }

    // Scene

    public var spheres : Array<Sphere>;
    public var plane : Plane;
    /*
      function init_scene() : void
      {
      spheres = [
      new Sphere(new Vec3(-2.0, 0.0, -3.5), 0.5),
      new Sphere(new Vec3(-0.5, 0.0, -3.0), 0.5),
      new Sphere(new Vec3(1.0, 0.0, -2.2), 0.5)
      ];
      plane = new Plane(new Vec3(0.0, -0.5, 0.0), new Vec3(0.0, 1.0, 0.0));
      }*/

    public static function createArray<A>(len : Int) : Array<A> {
        var xs = new Array<A>();
        for (i in 0...len) {
            xs.push(null);
        }
        return xs;
    }

    function ambient_occlusion(isect:Isect) : Vec3
    {
        var basis : Array<Vec3> = createArray(3);
        this.orthoBasis(basis,  isect.n);
        
        var p = new Vec3(
                         isect.p.x + AOBench.EPS * isect.n.x,
                         isect.p.y + AOBench.EPS * isect.n.y,
                         isect.p.z + AOBench.EPS * isect.n.z);

        var occlusion = 0;

        for (j in 0...AOBench.NPHI) {
            for (i in 0...AOBench.NTHETA) {
                var r   = Math.random();
                var phi = 2.0 * Math.PI * Math.random();
                var x   = Math.cos(phi) * Math.sqrt(1.0 - r);
                var y   = Math.sin(phi) * Math.sqrt(1.0 - r);
                var z   = Math.sqrt(r);

                // local -> global
                var rx = x * basis[0].x + y * basis[1].x + z * basis[2].x;
                var ry = x * basis[0].y + y * basis[1].y + z * basis[2].y;
                var rz = x * basis[0].z + y * basis[1].z + z * basis[2].z;

                var raydir = new Vec3(rx, ry, rz);
                var ray    = new Ray(p, raydir);

                var occIsect = new Isect();
                this.spheres[0].intersect(ray, occIsect);
                this.spheres[1].intersect(ray, occIsect);
                this.spheres[2].intersect(ray, occIsect);
                this.plane.intersect(ray, occIsect);

                if (occIsect.hit)
                    occlusion++;
            }
        }
        
        // [0.0, 1.0]
        var occ_f = (AOBench.ALLRAY - occlusion) / AOBench.ALLRAY;

        return new Vec3(occ_f, occ_f, occ_f);
    }

	
    public function render(ctx:CanvasRenderingContext2D, w:Int, h:Int)  {
        var cnt = 0;
        var half_w = w * .5;
        var half_h = h * .5;
        for (y in 0...h) {
            for (x in 0...w) {
                cnt++;
                var px =  (x - half_w)/half_w;
                var py = -(y - half_h)/half_h;
                
                var eye = Vec3.vnormalize(new Vec3(px, py, -1.0));
                var ray = new Ray(new Vec3(0.0, 0.0, 0.0), eye);
                
                var isect = new Isect();
                this.spheres[0].intersect(ray, isect);
                this.spheres[1].intersect(ray, isect);
                this.spheres[2].intersect(ray, isect);
                this.plane.intersect(ray, isect);
                
                var col = new Vec3(0.0,0.0,0.0);
                if (isect.hit)
                    col = this.ambient_occlusion(isect);
                
                var r = Math.round(col.x * 255.0);
                var g = Math.round(col.y * 255.0);
                var b = Math.round(col.z * 255.0);
                
                // use fill rect
                ctx.fillStyle = "rgb(" + r + "," + g + "," + b + ")";
                ctx.fillRect (x, y, 1, 1);	
            }
        }
        
    }

} // aobench

import js.Lib;

class Application {
    public static function main(canvasId : String, fpsId : String, quantity : Int) {

        var dom = Lib.document;
        var canvas : Dynamic = dom.getElementById(canvasId);
        var ctx : CanvasRenderingContext2D = canvas.getContext("2d");

        var ao = new AOBench();
        var t0 = Date.now().getTime();
        ao.render(ctx,256,256);
        var t1 = Date.now().getTime();
        var d = t1 - t0;
        dom.getElementById(fpsId).innerHTML = "Time = " + d + "[ms]";
    }
}

class Main {
    public static function main() {}
}