using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MatrixTransform {
    public partial class Form1 : Form {
        Triangle t;
        public Form1 () {
            InitializeComponent();
        }

        private void Form1_Paint (object sender, PaintEventArgs e) {
            e.Graphics.TranslateTransform(300, 300);
            t.Scale(1f, 0.2f);
            t.Draw(e.Graphics);
        }

        private void Form1_Load (object sender, EventArgs e) {
            PointF A = new PointF(0, -200);
            PointF B = new PointF(200, 200);
            PointF C = new PointF(-200, 200);
            t = new Triangle(A, B, C);
        }

        private void timer1_Tick (object sender, EventArgs e) {
            //t.Rotate(1);
            //this.Invalidate();
        }
    }
}
