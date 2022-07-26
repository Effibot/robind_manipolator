package com.effibot.robind_manipolator.modules.intro;

import com.dlsc.workbenchfx.Workbench;
import com.dlsc.workbenchfx.view.controls.ToolbarItem;
import com.effibot.robind_manipolator.Utils;
import com.effibot.robind_manipolator.bean.IntroBean;
import com.effibot.robind_manipolator.bean.RobotBean;
import com.effibot.robind_manipolator.bean.SettingBean;
import com.effibot.robind_manipolator.modules.setting.SettingModule;
import com.effibot.robind_manipolator.processing.Obstacle;
import com.effibot.robind_manipolator.processing.P2DMap;
import com.effibot.robind_manipolator.processing.ProcessingBase;
import com.effibot.robind_manipolator.tcp.Lock;
import com.effibot.robind_manipolator.tcp.TCPFacade;
import com.jfoenix.controls.JFXButton;
import com.jogamp.newt.opengl.GLWindow;
import javafx.embed.swing.SwingFXUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.imageio.ImageIO;
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeSupport;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.concurrent.BlockingQueue;

public class IntroController {
    private static final Logger LOGGER = LoggerFactory.getLogger(IntroController.class.getName());

    private final IntroModule introModule;
    private final ProcessingBase sketch;
    private final Workbench wb;
    TCPFacade tcp = TCPFacade.getInstance();
    private final BlockingQueue<LinkedHashMap<String, Object>> queue;

    private IntroBean introBean;
    PropertyChangeSupport changes = new PropertyChangeSupport(this);
    private Thread t=null;

    private static final Lock lock = new Lock();
    private SettingBean settingBean;
    private RobotBean robotBean;
    private static final String WIKICONTENT = """
                All'apertura della finestra secondaria
                cliccare su di essa per posizionare gli
                ostacoli.Poi tornare sulla finestra
                principale per annullare o confermare
                la selezione.
                Per retrocedere alla schermata principale
                chiudere la tab.
                """;

    public IntroController(IntroModule introModule, ProcessingBase sketch, Workbench workbench) {
        this.introModule = introModule;
        this.queue = tcp.getQueue();
        this.sketch = sketch;
        this.wb = workbench;
        this.sketch.run(this.sketch.getClass().getSimpleName());
        addPropertyChangeListener(tcp);

    }

    public void notifyPropertyChange(String propertyName, Object oldValue, Object newValue) {
        /*
         * Just a wrapper for the fire property change method.
         */
        changes.firePropertyChange(propertyName, oldValue, newValue);
    }
    public void addPropertyChangeListener(PropertyChangeListener l) {
        changes.addPropertyChangeListener(l);
    }

    public void onRedoAction(JFXButton btn, ProcessingBase pb) {
        btn.setOnMouseClicked(event -> {

            ArrayList<Obstacle> obsList = ((P2DMap) pb).getObstacleList();
            if (!obsList.isEmpty()) {
                obsList.remove(obsList.size() - 1);
                ((P2DMap) pb).setObstacleList(obsList);
            }
        });
    }
    private SettingModule sm = null;
    public void onContinueAction(JFXButton btn, Workbench wb, ProcessingBase pb) {

        btn.setOnAction(event -> {
            introBean = new IntroBean();
            this.settingBean = new SettingBean();
            this.robotBean = new RobotBean();
            this.robotBean.setObsList(((P2DMap)sketch).getObstacleList());
            sm = new SettingModule(settingBean,robotBean,wb);
            introBean.setObsList(Utils.obs2List(((P2DMap) pb).getObstacleList()));

            if(t!=null)
                t.interrupt();
            else{
                t = getNewThread();
                t.start();
            }
            synchronized (lock){
       
                lock.lock();
                LOGGER.info("I'm unlocking and notifying");
                lock.notifyAll();
            }
            GLWindow pane = (GLWindow)sketch.getSurface().getNative();
            pane.destroy();
            introModule.close();
            wb.getModules().remove(introModule);
            wb.getModules().add(sm);
            wb.openModule(sm);



        });
    }

    private Thread getNewThread() {
        return new Thread(()->{
            synchronized (lock){
                try {
                    while (!lock.isLocked()) {
                        LOGGER.info("I'm waiting");
                        lock.wait();
                    }
                } catch (Exception e) {
                    Thread.currentThread().interrupt();
                }

                LOGGER.info("Running MakeMap");

                makeMap();
            }
        });
    }

    public void makeMap() {
        try {
            LinkedHashMap<String, Object> pkt = new LinkedHashMap<>();
            pkt.put("PROC", "MAP");
            pkt.put("DIM", new double[]{1024.0, 1024.0});
            pkt.put("OBSLIST", introBean.getObsList());
            notifyPropertyChange("SEND", null, pkt);
            notifyPropertyChange("RECEIVE", false, true);
            boolean finish = false;
            while (!finish) {
                // set green id

                pkt = queue.take();

                String key = (String) (pkt.keySet().toArray())[0];
                switch (key) {
                    case "ID" -> settingBean.setGreenId((double[]) pkt.get(key));
                    case "BW" -> settingBean.setRaw((byte[]) Utils.decompress((byte[]) pkt.get(key)));
                    case "SHAPE" -> settingBean.setShapeList((double[][]) pkt.get(key));
                    case "ANIMATION" -> settingBean.setAnimation((byte[]) Utils.decompress((byte[]) pkt.get(key)));
                    case "SHAPEIDS" -> {
                        ArrayList<double[]> greenIdShape = new ArrayList<>();
                        greenIdShape.add((double[]) pkt.get("SFERA"));
                        greenIdShape.add((double[]) pkt.get("CONO"));
                        greenIdShape.add((double[]) pkt.get("CUBO"));
                        settingBean.setShapeIdList(greenIdShape);
                    }
                    case "FINISH" -> {
                        finish = true;
                        if((Double)pkt.get(key)!=-99d) settingBean.setFinish(true);

                    }
                    default -> LOGGER.info("Not Mapped Case");
                }
            }
        }
        catch (InterruptedException e) {
            LOGGER.debug( " Take Queue Interrupted!", e);
            Thread.currentThread().interrupt();
        }finally {
            File fl = new File("src/main/resources/com/effibot/robind_manipolator/img/textureImg.png");
            try {
                ImageIO.write(SwingFXUtils.fromFXImage(sm.getMap(),null),"png",fl);
            } catch (IOException e) {
                LOGGER.error("Unable to make Texture",e);
                Thread.currentThread().interrupt();
            }
            Thread.currentThread().interrupt();
        }

    }

    public void setOnHoverInfo(ToolbarItem toolbarItem) {
        toolbarItem.setOnClick(evt->
            wb.showInformationDialog(
                    "Wiki "+introModule.getName(),
                    WIKICONTENT,
                    buttonType ->{}
            )
        );

    }
}