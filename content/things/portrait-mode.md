---
title: "Why your phone’s portrait mode fakes the blur"
date: "2021-01-15"
live: false
# socialmediaimage: "social.png"
---

Portrait mode blurs out the part of the image that is in the background to make it look... “better”. Turns out the reason for this is physics more than anything else.

<!-- more -->

<link rel="stylesheet" href="/lab/diagram/geometry.css" />

Alright, I will admit: The titular question is not actually the question that prompted me to write this article. Originally, I wanted to understand why smaller apertures (i.e. higher $f$-Numbers) make your image sharper. Later I wanted to figure out if the [significantly bigger sensor in the Ricoh GR III will get me better background blur than the Canon PowerShot G7 X Mark III][camera comparison]. Researching this I realized that I can now also answer the question why phones add the background blur artifically.

<figure>
  <img src="./comparison.jpg" width="1280" height="563">
  <figcaption>
    Left: Picture taken  on my Pixel 5.<br>
    Middle: The same picture, but in “Portrait mode”.<br>
    Right: A picture taken with my (full-frame) Canon EOS R with my zoom lens at 46mm at f/2.8.<br>
    All pictures cropped to the same aspect ratio (2:3) and slightly color-graded.
</figure>

Before we can talk about cameras and sensors and what an $f$-Number is, we have to go back to school and catch up on some basic optics!

## Optics
In the earlier days of photography, lenses were simple. Today’s lenses, on the other hand, are quite complicated. They fulfil the same purpose, but with a whole bunch of benefits over their earlier counterparts. To keep this article somewhat manageable, I will focus on the earlier simpler lenses. Not only that, but I will assume that we are working with “perfect” lenses throughout this article. They don’t have any chromatic abberation (i.e. they don’t bend different wave lengths differently), they don’t have vignetting (i.e. the don’t lose light at the edges) and they are “thin” lenses (i.e. they can be modeled with simplified formulas). I will also only look at spherical, bi-convex lenses. Those lenses are convex on both sides (have a belly-like shape) and their curvature is that of a sphere. Contemporary camera lenses contain all kinds of lenses (concave, convex-concave, aspherical, etc).

### Lenses

The two most important parameters of a lens for this excursion is its focal length $f$ and diameter $A$. The diameter is literally that, determining the size of the piece of glass. The focal length describes the distance of the center of the lens to the focal point, which also the center of the circle (or sphere, rather) that gives the lens its curvature. The smaller the focal length, the more the light rays are bent torwards the focal point when they pass through the lens. The bigger the focal length $f$, the less they get bent. For thin lenses, rule is that rays that enter the lens parallel to the lens axis, will intersect the focal point.

<figure>

|||geometry
 {
    width: 500,
    height: 300,
    viewBox: {
      leftX: -200,
      rightX: 300,
      topY: -150,
      bottomY: 150,
    },
    handles: {
      fp: new geometry.Point(150, 0).setName("fp"),
    },
    recalculate() {
      const rayGap = 14;
      const aperture = 150;
      this.handles.fp.y = 0;
      this.handles.fp.x = Math.max(this.handles.fp.x, aperture/3);
      const lensCenter = new geometry.Point(0, 0);
      const lens = new geometry.Lens(lensCenter, this.handles.fp.difference(lensCenter), aperture);
      const lensplane = lens.asLine();
      const lensaxis = lens.axis();
      const fp = lens.focalPoint();
      const otherFp = lens.otherFocalPoint();
      const axis = lens.axis();
      const top = lens.top();
      const rays = Array.from({length: Math.round(lens.aperture / rayGap)}).map((_, i) => {
        const p1 = top.add(lensplane.pointAtDistance(-i * rayGap)).addSelf(new geometry.Point(-999, 0));
        const p2 = lensplane.project(p1);
        const ray = new geometry.HalfSegment(p2, p1);
        return [
          ray,
          new geometry.Arrow(ray.pointAtDistance(40), p1),
          new geometry.HalfSegment(p2, fp)
        ];
      }).flat();
      const bottomLine = new geometry.Line(new geometry.Point(0, 120), new geometry.Point(1, 0));
      const focalLengthStart = bottomLine.project(lens.bottom());
      return [
        ...rays.map(r => r.addClass("ray")),
        lens.addClass("lens"), 
        lensplane.addClass("lensplane"), 
        otherFp,
        axis.addClass("axis"),
        new geometry.MeasureLine(focalLengthStart, bottomLine.project(this.handles.fp)).addClass("focallength"),
        new geometry.Text(this.handles.fp.add(new geometry.Point(10, -5)), "Focal point"),
        new geometry.Text(lensplane.pointAtDistance(120), "Lens plane"),
        new geometry.Text(axis.pointAtDistance(-180), "Lens axis"),
        new geometry.Text(focalLengthStart.add(new geometry.Point(5, -5)), "Focal length"),
      ];
    },
  }
|||

<figcaption>Rays that enter the lens parallel to the lens axis will intersect the focal point.<br>(Orange points are interactive!)</figcaption>
</figure>

The reverse works as well: Rays that enter the lens by crossing the focal point will exit the lens parallel to the lens axis. This rule is surprisingly powerful and will allow us to derive a whole lot of interesting facts.

> **Note:** You’ll notice that lenses with a short focal length are anything but thin. We’ll still pretend that they fall into the “thin lens” category for the remainder of this article.

Light in real life is barely ever parallel, but rather radiating out into all directions. More specifically, apart from a few notable exceptions (like mirrors), every material reflects the light that it is hit by evenly into all directions. Let’s imagine we have a point that sends light rays into all directions and we put it on one side of our lens. Considering that people were able to take pictures with these simple lenses, there has to be a place on the other side of the lens where all the light rays geet focused back into a single point. 

While there will be light rays hitting every part of our lens, we only need to focus on two of them to figure this out: The one light ray that is parallel to the lens axis, and the other ray that intersects the focal point. We know how these rays will behave and they will (most likely) also intersect on the _other_ side of the lens. And where these two lines cross, all other rays will intersect as well.

<figure>

|||geometry
 {
    width: 500,
    height: 300,
    viewBox: {
      leftX: -200,
      rightX: 300,
      topY: -150,
      bottomY: 150,
    },
    handles: {
      p: new geometry.Point(-150, -20).setName("p"),
      fp: new geometry.Point(50, 0).setName("fp"),
    },
    recalculate() {
      const lensCenter = new geometry.Point(0, 0);
      this.handles.fp.y = 0;
      const lens = new geometry.Lens(lensCenter, this.handles.fp.difference(lensCenter), 150);

      this.handles.p.x = Math.min(this.handles.p.x, lens.otherFocalPoint().x - 1);
      const lensplane = lens.asLine()
      const otherFp = lens.otherFocalPoint();
      const axis = lens.axis();
      const { point, ray1a, ray1b, ray2a, ray2b } = lens.lensProject(
        this.handles.p
      );
      const {polygon, ray1, ray2} = lens.lightRays(this.handles.p, {projectedP: point});
      const bottomLine = new geometry.Line(new geometry.Point(0, 120), new geometry.Point(1, 0));
      return [
        ...[ray1a, ray1b, ray2a, ray2b].map(v => v.addClass("constructionray")),
        lens.addClass("lens"), 
        lensplane.addClass("lensplane"), 
        polygon.addClass("light"),
        otherFp,
        axis.addClass("axis"),
        new geometry.Text(this.handles.fp.add(new geometry.Point(10, -5)), "Focal point"),
        point,
        new geometry.MeasureLine(bottomLine.project(lensCenter), bottomLine.project(this.handles.p)).addClass("focallength"),
        new geometry.MeasureLine(bottomLine.project(lensCenter), bottomLine.project(point)).addClass("focallength"),
        new geometry.Text(bottomLine.project(lensCenter).add(new geometry.Point(-20, -5)), "s"),
        new geometry.Text(bottomLine.project(lensCenter).add(new geometry.Point(20, -5)), "s'"),
      ];
    },
  }
|||

<figcaption>A lens focuses light rays onto a point.</figcaption>

</figure>

The point on the left is often just called “object”, while point on the right is called the “image”. From this _geometric_ construction we can derive a nice formula describing the relationship between the object’s distance and the image’s distance from the center of the lens:

<figure>

$$
\frac{1}{s} + \frac{1}{s'} = \frac{1}{f}
$$

<figcaption>

The “thin lens equation” describes the relationship between the object’s distance $s$, and the image’s distance $s'$ and the lens’ focal length $f$.

</figcaption>
</figure>

## Photography

You’ll notice that if you move the object parallel to the lens plane, the image will also move parallel to the lens plane, although in the opposite direction. This tells us two things: Firstly, the image is upside down. Secondly, instead of talking about individual points and where their image is, we can talk about the “image plane” and the focal plane”. We have now entered the territory of photography.

### The image plane & the focal plane

To take a picture we have to have something that... takes the picture. Yes. Very good explanation. In analogue photography, that is the film or photo paper, in digital cameras — and for the remainder of this article — it’s the sensor. The distance of the sensor to the lens determines which part of the world is “in focus”. The size of the sensor, combined with the focal length of the lens determines the angle of view that will be capture. While some cameras and lenses allow you to have arbitrary angles between image plane and lens plane, we will keep them parallel to each other. For now.

Note that in all the previous diagrams the direction of the light is actually irrellevant. The roles of object and image can be reversed and the diagrams wouldn’t change. With this observation, we can answer the question where the focal plane is. We can place our sensor on one side of the lens, and project it through the lens. The “image” of the sensor is the area of the real world that is in focus; the part of the world that will be projected onto the sensor.

<figure>

|||geometry
 {
    width: 800,
    height: 300,
    viewBox: {
      leftX: -150,
      rightX: 650,
      topY: -150,
      bottomY: 150,
    },
    handles: {
      l: new geometry.Point(100, 0),
      s: new geometry.Point(-80, -50),
      fp: new geometry.Point(220, 0),
    },
    recalculate() {
      this.handles.s.x = this.viewBox.leftX + 20;
      this.handles.s.y = Math.min(this.handles.s.y, 1);
      this.handles.l.y = 0;
      this.handles.l.x = Math.max((this.handles.fp.x + this.handles.s.x) / 2 + 1, this.handles.l.x);
      this.handles.fp.y = 0;
      this.handles.fp.x = Math.max(this.handles.l.x + 10, this.handles.fp.x);
      const lensCenter = this.handles.l;
      const fp = this.handles.fp.difference(lensCenter);
      const lens = new geometry.Lens(lensCenter, fp, 150);

      const sensorplane = new geometry.Line(this.handles.s, new geometry.Point(0, 1));
      const sensorTop = this.handles.s;
      const sensorBottom = this.handles.s.mirrorOn(sensorplane.project(lensCenter));
      const sensor = new geometry.Arrow(sensorTop, sensorBottom);

      const {point: sensorTopP} = lens.lensProject(sensorTop);
      const {point: sensorBottomP} = lens.lensProject(sensorBottom);
      const sensorP = new geometry.Arrow(sensorTopP, sensorBottomP);
      const focalPlane = sensorP.line();
      const angle = new geometry.Polygon(this.handles.fp, sensorTopP, sensorBottomP);
      const lensTop = lens.plane().project(sensorTop);
      const lensBottom = lens.plane().project(sensorBottom);
      const ray1 = new geometry.HalfSegment(lensBottom, this.handles.fp);
      const ray2 = new geometry.HalfSegment(lensTop, this.handles.fp);
      const topline = new geometry.Line(new geometry.Point(0, -120), new geometry.Point(1, 0));
      const bottomline = new geometry.Line(new geometry.Point(0, 120), new geometry.Point(1, 0));
      const gap = new geometry.Point(10, 0);
      const focallength = new geometry.MeasureLine(bottomline.project(this.handles.l), bottomline.project(this.handles.fp))
      return [
        sensorplane.addClass("sensorplane"),
        focalPlane.addClass("focalplane"),
        sensor.addClass("sensor"),
        lens.addClass("lens"),
        new geometry.Text(topline.project(this.handles.s).addSelf(gap), "Sensor plane"),
        new geometry.Text(sensorTop.add(sensorBottom).scalarSelf(1/2).addSelf(gap), "D"),
        new geometry.Text(topline.project(sensorTopP).addSelf(gap), "Focal plane"),
        new geometry.Text(this.handles.fp.add(gap.scalar(3)), "α").addClass("text-middle"),
        sensorP.addClass("sensor"),
        angle.addClass("fov"),
        new geometry.Segment(sensorTop, lensTop).addClass("dashed"),
        new geometry.Segment(sensorBottom, lensBottom).addClass("dashed"),
        ray1.addClass("dashed"),
        ray2.addClass("dashed"),
        new geometry.Arc(this.handles.fp, 50, ray1.pointAtDistance(900), ray2.pointAtDistance(900)).addClass("arc"),
        focallength,
        new geometry.Text(focallength.middle().addSelf(gap.orthogonal()), "f"),
      ];
    },
  }
|||

<figcaption>A lens focuses light rays onto a point.</figcaption>

</figure>

This leads us to two conclusions: The focal length is directly related to the angle of view. A longer focal length has a smaller angle of view, effectively creating a zoomed-in picture. Similarly, the same lens on a larger will yield a larger angle of view. More specifically, the relationship between sensor size, focal length and angle of view can be described as follows:

<figure>

$$

\frac{D}{2f} = \tan \alpha

$$

<figcaption>

The formula describing the relationship between angle of view $\alpha$, the sensor size $D$ and the focal length $f$.

</figcaption>
</figure>

### Focusing

In the demo above, you can move the lens and change the lens’ focal length to see how it affects the focal plane. However in photography you don’t move the lens and see where our focus plane ends up, you have something that you want to focus _on_, and want to position your lens accordingly. If we know the distance $S$ between our sensor plane and our desired focal plane, we can use the thin lens equation to figure where to place the lens:

$$
\begin{array}{rc}
  & \frac{1}{f} = \frac{1}{s} + \frac{1}{s'} \\
  \Leftrightarrow & \frac{1}{f} = \frac{1}{s} + \frac{1}{S - s} \\
  \Leftrightarrow & ... \\
  \Rightarrow & s = \frac{S}{2} \pm \sqrt{\frac{S^2}{4} - Sf} \\
\end{array}
$$

Apologies for skipping the math there in the middle, but it’s really just a bunch of transformations until you can use the [quadratic formula]. The majority of cameras don’t use this formula as they don’t measure the distance to the target, but go by other means. But something interesting can be derived from this result: For the result to exist, the expressing in the square root must be positive, i.e:

$$
\begin{array}{rcl}
  \frac{S^2}{4} - Sf & > & 0 \\
  \Leftrightarrow S & > & 4f \\
\end{array}
$$

That means, to be able to focus on a subject with lens with focal lens $f$, the subject needs to be at least four times the focal length away from the sensor.

## Bokeh

Now that we know how to focus, determine the focal plane and even determine lens position with a given focal plane, we can take a look what happens when something is _out_ of focus. Looking at the image at the start of the article, you can see the fairly lights turning into larger circles of light, often refferred to as “Bokeh”. Bokeh is Japanese for “blur”, and as such _technically_ refers to anything that is out of focus, but depending on context, it can also be used to refer to point lights specifically.

<figure>

|||geometry
 {
    width: 930,
    height: 480,
    viewBox: {
      leftX: -30,
      rightX: 900,
      topY: -220,
      bottomY: 260,
    },
    handles: {
      p: new geometry.Point(0, -120),
      fp: new geometry.Point(0, 120),
      d: new geometry.Point(0, -40),
    },
    recalculate() {
      const op = new geometry.Point(this.viewBox.rightX-20, 10);
      const center = (this.viewBox.leftX + this.viewBox.rightX) / 2;
      const topLine = new geometry.Line(new geometry.Point(0, this.viewBox.topY + 20), new geometry.Point(1, 0));
      const topLineB = new geometry.Line(new geometry.Point(0, this.viewBox.topY + 40), new geometry.Point(1, 0));
      const topLineC = new geometry.Line(new geometry.Point(0, this.viewBox.topY + 80), new geometry.Point(1, 0));
      const bottomLine = new geometry.Line(new geometry.Point(0, this.viewBox.bottomY - 10), new geometry.Point(1, 0));
      const slider = new geometry.MeasureLine(
        bottomLine.project(new geometry.Point(center - 100, 0)),
        bottomLine.project(new geometry.Point(center + 100, 0)),
      );
      const ffactor = geometry.clamp(0, slider.whereIs(this.handles.fp)/slider.length(), 1);
      this.handles.fp = slider.pointAtDistance(ffactor*slider.length());
      const f = geometry.remap(0, 1, 80, 140)(ffactor);
      this.handles.p = topLine.project(this.handles.p);
      this.handles.p.x = Math.max(4*f, this.handles.p.x);
      const lens = new geometry.Lens(new geometry.Point(0, 0), new geometry.Point(f, 0), 130);

      const focalplane = new geometry.Line(this.handles.p, new geometry.Point(0, 1));
      const sensorplane = new geometry.Line(new geometry.Point(0, 0), new geometry.Point(0, 1));
      const sensorTop = sensorplane.pointAtDistance(120);
      const sensorBottom = sensorplane.pointAtDistance(-120);
      const sensor = new geometry.Segment(sensorTop, sensorBottom);
      const pointToSensor = this.handles.p.x - sensor.point.x;
      const dlp = pointToSensor/2 + Math.sqrt(pointToSensor**2/4 - pointToSensor * f);
      const dsl = pointToSensor - dlp;
      lens.center.x = sensor.point.x + dsl;

      this.handles.d.x = lens.center.x;
      this.handles.d.y = -geometry.clamp(20, -this.handles.d.y, 120);
      lens.aperture = Math.abs(this.handles.d.y * 2);

      const fp = lens.focalPoint();
      const ofp = lens.otherFocalPoint();

      const {polygon, ray1, ray2, projectedP} = lens.lightRays(op);
      const p1 = sensorplane.intersect(ray1);
      const p2 = sensorplane.intersect(ray2);
      const p = new geometry.Segment(p1, p2);
      const gap = new geometry.Point(10, 0);
      const lensSize = new geometry.MeasureLine(lens.top().addSelf(gap.scalar(-2)), lens.bottom().addSelf(gap.scalar(-2)));
      const Df = new geometry.MeasureLine(sensorplane.intersect(topLineB), topLineB.project(this.handles.p)).shrinkSelf(2);
      const DL = new geometry.MeasureLine(sensorplane.intersect(topLineC), topLineC.project(op)).shrinkSelf(2);
      const bottomLineB = new geometry.Line(new geometry.Point(0, this.viewBox.bottomY - 80), new geometry.Point(1, 0));
      const bottomLineC = new geometry.Line(new geometry.Point(0, this.viewBox.bottomY - 120), new geometry.Point(1, 0));
      const sfp = new geometry.MeasureLine(sensorplane.intersect(bottomLineB), bottomLineB.project(lens.bottom())).shrinkSelf(2);
      const sf = new geometry.MeasureLine(bottomLineB.project(lens.bottom()), bottomLineB.intersect(focalplane)).shrinkSelf(2);
      const slp = new geometry.MeasureLine(bottomLineC.project(projectedP), bottomLineC.project(lens.bottom())).shrinkSelf(2);
      const sl = new geometry.MeasureLine(bottomLineC.project(lens.bottom()), bottomLineC.project(op)).shrinkSelf(2);
      return [
        op,
        sensorplane.addClass("sensorplane"),
        focalplane.addClass("focalplane"),
        sensor.addClass("sensor"),
        lens.addClass("lens"),
        polygon.addClass("light"),
        p.addClass("image"),
        new geometry.Text(this.handles.p.add(gap), "Focal plane"),
        new geometry.Text(sensorplane.intersect(topLine).addSelf(gap), "Sensor plane"),
        fp,
        ofp,
        new geometry.Text(slider.middle().addSelf(gap.orthogonal()), "Focal length").addClass("text-hmiddle"),
        slider,
        lensSize,
        new geometry.Text(lens.top().addSelf(gap.scalar(-4)), "A").addClass("text-hmiddle"),
        Df,
        new geometry.Text(Df.middle().addSelf(gap.orthogonal().scalarSelf(-2)), "D<tspan baseline-shift=sub>focal</tspan>"),
        DL,
        new geometry.Text(DL.middle().addSelf(gap.orthogonal().scalarSelf(-2)), "D<tspan baseline-shift=sub>light</tspan>"),
        sfp,
        new geometry.Text(sfp.middle().addSelf(gap.orthogonal().scalarSelf(-2)), "s'<tspan baseline-shift=sub>focal</tspan>"),
        sf,
        new geometry.Text(sf.middle().addSelf(gap.orthogonal().scalarSelf(-2)), "s<tspan baseline-shift=sub>focal</tspan>"),
        slp,
        new geometry.Text(slp.middle().addSelf(gap.orthogonal().scalarSelf(-2)), "s'<tspan baseline-shift=sub>light</tspan>"),
        sl,
        new geometry.Text(sl.middle().addSelf(gap.orthogonal().scalarSelf(-2)), "s<tspan baseline-shift=sub>light</tspan>"),
        lens.asLine().addClass("lensplane"),
      ];
    },
  }
|||

<figcaption>A lens focuses light rays onto a point.</figcaption>

</figure>

The further a point is away from the focus plane, the more area it will consume on the sensor. Technically, a point will only be projected into a point when it is _exactly_ on the focal plane. Even the smallest deviation to either of the focal plane makes the point turn into a circle, which is what is called being “out of focus”. Of course, a tiny small circle is humanly indistinguishable from a point. The area around the focal plane that every point _appears_ in focus to a human is called the focus area.

> **Circle of confusion:** I won’t cover this topic in depth, but the biggest circle that is perceived as a point by a human is called the [circle of confusion]. It plays a central role in calculating the focus area. One thing I _will_ say about the circle of confusion, though: Many articles list “traditional” diameters for the circle of confusion depending on sensor size (e.g. 0.029mm for a full frame sensor). These are based on printing the a picture on a piece of paper on a certain size and looking at it from a certain distance. In the digital age, however, we crop and we zoom. Something that looks in-focus on Instagram can look completely out of focus once zoomed in. If you want to make sure something in focus even after zooming in, your diameter for the circle of confusion is the size of a single pixel on the sensor — because any circle that is at most the size of a pixel will still be captured as a single pixel. This has implications: You’ll find that this leaves you very little room for error as a photograpgher. Using the “traditional” circle of confusion yields a focus area of 1.5m, while the pixel-based circle of confusion makes it shrink to just ~28cm.

The main takeaway from the diagram above is that there are two factors influencing the size of a circle on the sensor: The lens diameter $A$ and the point’s distance from the focal plane. Keeping everything else constant, a smaller lens diameter will create a smaller circle on the sensor, which in turn makes it _appear_ sharper. Or to phrase it another way: A smaller diameter creates a bigger focus area.

### Lens size & shape

Lenses are made of glass, so you can’t just change their size. But we just learned that a smaller lens diameter will increase sharpness (technically, it increases the focus area), so it’s a useful variable to be able to change. To address this, lenses have an iris to artifically change the size of a lens.

<figure>
  <img src="iris.jpg" loading="lazy" width="800" height="800" style="max-width: 800px">
  <figcaption>
  
  The iris of a lens, consisting of 16 blades.

  </figcaption>
</figure>

The diagrams are not really good at visualizing it, but the shape of a lens will determine what a point light will look like when it’s out of focus. Pretty much all photography lenses are circular, which is why point lights turn into circles. The iris, however, is made of blades and is not _perfectly_ circular. The iris shown above is a 16-blade iris, which is rare. Most lenses I know have between 7 and 9 blades, and you can see the the not-quite-perfectly-circular iris affecting the look of light circles, for example in movies.

<figure>
  <img src="sherlock.jpg" loading="lazy" width="1280" height="719" style="max-width: 1280px">
  <figcaption> A screenshot from the pilot episode of BBC’s “Sherlock” (2010). The lights in the background are out of focus and their jagged outline lets us count the number of blades used for the iris of the lens. </figcaption>
</figure>

Lensbaby takse advantage of the fact that out-of-focus spot lights take the shape of the lens opening and allows you to put shapes inbetween the lens and sensor:

<figure>
  <img src="lensbaby.jpg" loading="lazy" width="1280" height="219" style="max-width: 1280px">
  <figcaption>Lensbaby lens using a nice swirl or something. Waiting for Ingrid.</figcaption>
</figure>

### f-stops

We have talked about the lens diameter, but the diameter of a lens is rarely talked about directly in photography. Instead, they talk about the focal lens $f$ and the _aperture_, which is given as a $f$-Number. For example, the picture at the beginning of the blog post I took with a lens where $f = 46mm$ and an aperture of $f/2.8$. This $f$-Number _is_ the lens diameter, just given as a fraction of the focal length $f$. So in this case $A = \frac{f}{2.8} = 17.1mm$. The reason that photographers use $f$-Numbers is that two lenses will allow the same amount of light to hit their <strike>film</strike> sensor, if they have the same aperature — regardless of focal length. For example, $50mm$ lens with a diameter of 25mm ($f/2.0$) lets in the same amount of light as a $100mm$ lens with a diameter of 50mm ($f/2.0$) and produces an equally bright image.

### Bokeh size

How big is the circle on the sensor given a certain constellation? Looking at the rays on the left side of lens in diagram above, we can use the law of similar triangles (or more specifically the [intercept theorem]) to establish the following relationship between the lens aperture $A$ and the bokeh circle size $c$:

$$
  \frac{A}{s'_{\text{light}}} = \frac{c}{s'_{\text{focal}} - s'_{\text{light}}}
$$

To get the values for $s'_\text{light}$ and $s'_\text{focal}$ we can use the focusing equation above to parameterize the formula with the distance $D_\text{focal}$ of sensor plane and focal plane, and distance $D_\text{light}$ of sensor plane and point light:

$$
  c = A \left( \frac{\frac{D_\text{focal}}{2} + \sqrt{\frac{D_\text{focal}^2}{4} - D_\text{focal}\cdot f}}{\frac{D_\text{light}}{2} - \sqrt{\frac{D_\text{light}^2}{4} - D_\text{light}\cdot f}} - 1 \right)
$$

Admittedly, this formula isn’t very helpful or even allows us to build an intuition. So let’s look at the extreme case: The focal plane as close as possible to the lens ($D_\text{focal} = 4f$), while the point light is inifitely far away ($D_\text{light} \rightarrow \infty$). In this scenario, the formula drastically simplifies (provided you can [calculate the limit][limit], which I couldn’t without help):

$$
c = 2\cdot A
$$

I found this _fascinating_. In the extreme case, the focal length actually has _no_ influence over the size of the bokeh circles. Aperture and aperture alone dictates how big the circle on the sensor is.

## Sensor size

Let’s return at the original comparison image from the start of the article. What kind of lens does a Pixel 5 have exactly? And what kind of sensor? Luckily, some of this data is embedded in the EXIF data of the images and can be extracted using `identify` from ImageMagick:

```
$ identify -format 'f=%[EXIF:FocalLength] A=%[EXIF:FNumber]' cam_image.jpg
f=46/1 A=28/10

$ identify -format 'f=%[EXIF:FocalLength] A=%[EXIF:FNumber]' pixel5_image.jpg
f=4380/1000 A=173/100
```

This says that my digital camera image was taken with $f=46mm$ and $f/2.8$ ($A=16.4mm$). The Pixel 5 used $f=4.38mm$ and $f/1.73$ ($A=2.5mm$). 

<figure>

|||geometry
 {
    width: 800,
    height: 300,
    viewBox: {
      leftX: -10,
      rightX: 790,
      topY: -150,
      bottomY: 150,
    },
    handles: {
      s: new geometry.Point(0, -50),
      fp: new geometry.Point(220, 0),
    },
    recalculate() {
      this.handles.s.x = this.viewBox.leftX + 20;
      this.handles.s.y = geometry.clamp(-100, this.handles.s.y, -10);
      this.handles.fp.y = 0;
      this.handles.fp.x = Math.max(400, this.handles.fp.x);
      const alpha = 50;
      const f = Math.abs(this.handles.s.y)*2 / (2* Math.tan(alpha /360 * 2 *Math.PI));
      const lensCenter = new geometry.Point(this.handles.fp.x/2 - Math.sqrt(this.handles.fp.x**2/4 - this.handles.fp.x *f), 0);
      const lens = new geometry.Lens(lensCenter, new geometry.Point(f, 0), 50);

      const sensorplane = new geometry.Line(this.handles.s, new geometry.Point(0, 1));
      const sensorTop = this.handles.s;
      const sensorBottom = this.handles.s.mirrorOnLine(geometry.Line.xAxis());
      const sensor = new geometry.Segment(sensorTop, sensorBottom);

      return [
        sensorplane.addClass("sensorplane"),
        sensor.addClass("sensor"),
        lens.addClass("lens"),
      ];
    },
  }
|||

<figcaption>A lens focuses light rays onto a point.</figcaption>

</figure>



<figure>
  <img src="lensbaby.jpg" loading="lazy" width="1280" height="219" style="max-width: 1280px">
  <figcaption>The same image cropped in to emulate a smaller sensor. The bokeh appears to be bigger.</figcaption>
</figure>

> **More lies:** I am ignoring the fact that the Pixel 5’s portrait mode crops in, effectively zooming in and giving the phone a longer focal length. Longer focal lenses are typically deemed more flattering for portraits as they have less perspective distortion. Whether this is a technical limitation or a technique to force people to literally take a step back when taking picrtures, is unclear to me.

The aperture on the DSLR is almost 7 times as large as the phones aperture. We just established that in these extreme constellations (close subject, far-away spot light), aperture is the dictating factor of the bokeh circles. To achieve the same bluriness of the DSLR, the Pixel 5 would have to achieve the same aperture of $A=16.4mm = f/0.27$. 

Is such a phone lens possible? This is where I couldn’t find any answers. In my experience, any lens with an aperture bigger than $f/1.4$ is rare and increasingly expensive. Any aperture bigger than $f/1.2$ is virtually unheard of, although they do exist.

<figure>
  <img src="nikkornoct.jpg" loading="lazy" width="1084" height="476" style="max-width: 1084px">
  <figcaption>Nikon’s f/0.95 aperture made waves amongst photographers and will cost you a mere £8.3k.</figcaption>
</figure>

The reality seems to be different: Phones are small(-ish) and physical space is valuable and as such small sensors wil be built into phones. The [Pixel 5, for example, has a $10mm$ sensor][pixel5 sensor]. Smaller sensors require shorter focal lengths for a reasonable field of view, and shorter focal lengths have smaller apertures

## LEFTOVERS


$$
\begin{array}{rrcl}
  & \frac{D_\text{fullframe}}{2 \cdot 46mm} & = & \frac{D_\text{phone}}{2 \cdot 4.38mm}\\
  \Leftrightarrow & \frac{36mm}{2 \cdot 46mm} \cdot 2 \cdot 4.38mm & = & D_\text{phone} \\
  \Leftrightarrow & 3.43mm & = & D_\text{phone} \\
\end{array}
$$

From the diagram we can also learn a short focal length will create a bigger circle than a long focal length at the minimal focal distance. However, moving the focal plane ever so slightly away from the minimal focal length will make the circle shrink much quicker than a comparable focus shift on a longer focal length.

 How much area? Well I’m glad you asked! Our friend the thin lenses equation combined with the [intercept theorem] will let us answer this question. Given a lens with focal length $f$ and diameter $D$, a focal plane at distance $S$ from the sensor and a point at distance $P$ from the sensor, we can calculate the area $B$ that the point will be projected on:

$$
\begin{array}{c}
l = \frac{S}{2} - \sqrt{\frac{S^2}{4} - Sf} \\
D \div (S-l) = B \div l
\end{array}
$$

<figure>
  <img src="intrepid.jpg" loading="lazy" width="609" height="457" style="max-width: 609px">
  <figcaption>
  
  The [Intrepid Mk 4][intrepid] is a contemporary large-format camera, but works in the same way the first cameras did.

  </figcaption>
</figure>



<figure>

|||geometry
 {
    width: 500,
    height: 300,
    viewBox: {
      leftX: 0,
      rightX: 500,
      topY: -150,
      bottomY: 150,
    },
    handles: {
      fp: new geometry.Point(999, 0).setName("fp")
    },
    recalculate() {
      const f = 30;
      const lensCenter = new geometry.Point(1.2*f, 0);
      // Make the handle stay on a circle around the lens center
      this.handles.fp = this.handles.fp.difference(lensCenter).normalizeSelf().scalarSelf(3*f).addSelf(lensCenter);
      const lens = new geometry.Lens(lensCenter, this.handles.fp.difference(lensCenter).normalizeSelf().scalarSelf(f), 2*f);

      const sensorplane = new geometry.Line(new geometry.Point(0, 0), new geometry.Point(0, -1));
      const sensorTop = sensorplane.pointAtDistance(20);
      const sensorBottom = sensorplane.pointAtDistance(-20);
      const sensor = new geometry.Arrow(sensorBottom, sensorTop);

      const {point: projectedSensorTop} = lens.lensProject(sensorTop);
      const {point: projectedSensorBottom} = lens.lensProject(sensorBottom);
      const projectedSensorPlane = geometry.Line.throughPoints(projectedSensorTop, projectedSensorBottom);
      const projectedSensor = new geometry.Arrow(projectedSensorBottom, projectedSensorTop);

      const topLine = new geometry.Line(new geometry.Point(0, -70), new geometry.Point(1, 0));
      return [
        lens.addClass("lens"),
        lens.asLine().addClass("lensplane"),
        lens.axis().addClass("lensplane"),
        sensorplane.addClass("sensorplane"),
        sensor.addClass("sensor"),
        projectedSensor.addClass("sensor"),
        projectedSensorPlane.addClass("sensorplane"),
        new geometry.Text(projectedSensorPlane.intersect(topLine).add(new geometry.Point(10, 0)), "Focal plane"),
        new geometry.Text(new geometry.Point(10, -120), "Sensor plane"),
      ];
    },
  }
|||

<figcaption>A lens focuses light rays onto a point.</figcaption>

</figure>

This journey started in the context of camera lenses, but camera lenses are complext beasts. Even the simplest, so-called “prime lenses”, which are have one fixed focal length and cannot zoom, _are_ actually zoom lenses and consist of multiple lenses. We will discover _some_ of the reasons for this overwhelming amount of lenses later in this article.

<figure>
  <img src="camera-lens.jpg" style="max-width: 700px">
  <figcaption>Camera lenses consist of multiple lenses.</figcaption>
</figure>

For most intents and purposes, these series of individual lenses

<script src="/lab/diagram/geometry-intromate.js" type="module"></script>

[camera comparison]: https://www.dpreview.com/products/compare/side-by-side?products=ricoh_griii&products=canon_g7xiii
[intrepid]: https://intrepidcamera.co.uk/
[quadratic formula]: https://en.wikipedia.org/wiki/Quadratic_formula
[intercept theorem]: https://en.wikipedia.org/wiki/Intercept_theorem
[circle of confusion]: https://en.wikipedia.org/wiki/Circle_of_confusions
[limit]: https://twitter.com/DasSurma/status/1361293594435403778
[pixel5 sensor]: https://www.dxomark.com/google-pixel-5-camera-review-software-power/