using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Laser pointer for teleportation and object interaction///     
/// </summary>
public class LaserPointer : MonoBehaviour
{   
    /// <summary>
    /// Camera Rig Transform
    /// </summary>
    /// <remarks>
    /// Special thanks to Eric Van de Kerckhove for excellent tutorial information.
    /// </remarks>
    public Transform cameraRigTransform;    

    /// <summary>
    /// Teleport reticle prefab
    /// </summary>
    public GameObject teleportReticlePrefab;        

    /// <summary>
    /// Player's Head (camera)
    /// </summary>
    public Transform headTransform;    

    /// <summary>
    /// Reticle offset from the floor (prevent z-fighting)
    /// </summary>
    public Vector3 teleportReticleOffset;        

    /// <summary>
    /// Layer mask to filter areas that are transportable
    /// </summary>
    public LayerMask teleportMask;

    /// <summary>
    /// Laser's prefab
    /// </summary>    
    public GameObject laserPrefab;
    
    private GameObject reticle;       
    private Transform teleportReticleTransform;    
    private bool shouldTeleport;
    private SteamVR_TrackedObject trackedObj;        
    private GameObject laser;    
    private Transform laserTransform;    
    private Vector3 hitPoint;

    /// <summary>
    /// Access to controller
    /// </summary>
    private SteamVR_Controller.Device Controller
    {
        get 
        { 
            return SteamVR_Controller.Input((int)trackedObj.index); 
        }
    }

    /// <summary>
    /// Get tracked object on awake
    /// </summary>
    void Awake()
    {
        trackedObj = GetComponent<SteamVR_TrackedObject>();
    }

    /// <summary>
    /// Initialization
    /// </summary>
    void Start()
    {        
        laser = Instantiate(laserPrefab);     
        laserTransform = laser.transform;        
        reticle = Instantiate(teleportReticlePrefab);
        teleportReticleTransform = reticle.transform;
    }

    /// <summary>
    /// Frame render call
    /// </summary>
    void Update()
    {
        // if touchpad is held
        if (Controller.GetPress(SteamVR_Controller.ButtonMask.Touchpad))
        {
            RaycastHit hit;

            // shoot ray from controller, store point if there is a hit
            if (Physics.Raycast(trackedObj.transform.position, transform.forward, out hit, 100, teleportMask))
            {
                hitPoint = hit.point;
                ShowLaser(hit);                
                reticle.SetActive(true);                
                teleportReticleTransform.position = hitPoint + teleportReticleOffset;                
                shouldTeleport = true;
            }
        }
        else 
        {
            // hide laser on release
            laser.SetActive(false);
            reticle.SetActive(false);
        }

        if (Controller.GetPressUp(SteamVR_Controller.ButtonMask.Touchpad) && shouldTeleport)
        {
            Teleport();
        }
    }

    /// <summary>
    /// Show laser.
    /// </summary>
    /// <param name="hit">hit target</param>
    private void ShowLaser(RaycastHit hit)
    {
        // show laser
        laser.SetActive(true);
        
        // positon laser between controller and point where raycast hits
        // use lerp 50% to return middle point
        laserTransform.position = Vector3.Lerp(trackedObj.transform.position, hitPoint, .5f);
        
        // point the laser at the position where the raycast hit
        laserTransform.LookAt(hitPoint);
        
        // scale the laser so it fits between the two positions
        laserTransform.localScale = new Vector3(laserTransform.localScale.x, laserTransform.localScale.y,
            hit.distance);
    }

    /// <summary>
    /// Teleport player 
    /// </summary>
    private void Teleport()
    {        
        // set shouldTeleport flag to false when teleportation is in progress
        shouldTeleport = false;     
        reticle.SetActive(false);        

        // calculate difference between positions of the camera rig's center and player head
        Vector3 difference = cameraRigTransform.position - headTransform.position;        

        // reset y-position to 0 because calculation does not consider vertical position of player's head
        difference.y = 0;        

        // move camera position to position of the hit point and add calculated difference
        cameraRigTransform.position = hitPoint + difference;
    }
}