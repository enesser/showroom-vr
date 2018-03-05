using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class livereflections : MonoBehaviour {


     public ReflectionProbe probe;

   

    void Update()
    {
      

        probe.RenderProbe();
    }

}
