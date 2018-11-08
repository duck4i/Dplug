//-----------------------------------------------------------------------------
// LICENSE
// (c) 2018, Steinberg Media Technologies GmbH, All Rights Reserved
//-----------------------------------------------------------------------------
/*
This license applies only to files referencing this license,
for other files of the Software Development Kit the respective embedded license text
is applicable. The license can be found at: www.steinberg.net/sdklicenses_vst3

This Software Development Kit is licensed under the terms of the Steinberg VST3 License,
or alternatively under the terms of the General Public License (GPL) Version 3.
You may use the Software Development Kit according to either of these licenses as it is
most appropriate for your project on a case-by-case basis (commercial or not).

a) Proprietary Steinberg VST3 License
The Software Development Kit may not be distributed in parts or its entirety
without prior written agreement by Steinberg Media Technologies GmbH.
The SDK must not be used to re-engineer or manipulate any technology used
in any Steinberg or Third-party application or software module,
unless permitted by law.
Neither the name of the Steinberg Media Technologies GmbH nor the names of its
contributors may be used to endorse or promote products derived from this
software without specific prior written permission.
Before publishing a software under the proprietary license, you need to obtain a copy
of the License Agreement signed by Steinberg Media Technologies GmbH.
The Steinberg VST SDK License Agreement can be found at:
www.steinberg.net/en/company/developers.html

THE SDK IS PROVIDED BY STEINBERG MEDIA TECHNOLOGIES GMBH "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL STEINBERG MEDIA TECHNOLOGIES GMBH BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

b) General Public License (GPL) Version 3
Details of these licenses can be found at: www.gnu.org/licenses/gpl-3.0.html
//----------------------------------------------------------------------------------
*/
module dplug.vst3.vst3main;

alias IPluginFactory = void*; // TODO

import dplug.core.runtime;
import dplug.core.nogc;

template VST3EntryPoint(alias ClientClass)
{
    enum entry_InitDll = `export extern(System) bool InitDLL() nothrow @nogc { return true; }`;
    enum entry_ExitDll = `export extern(System) bool ExitDll() nothrow @nogc { return true; }`;
    enum entry_GetPluginFactory =
        "export extern(System) IPluginFactory GetPluginFactory() nothrow @nogc" ~
        "{" ~
        "    return GetPluginFactoryInternal!" ~ ClientClass.stringof ~ ";" ~
        "}";

    const char[] VST3EntryPoint = entry_InitDll ~ entry_ExitDll ~ entry_GetPluginFactory;
}

IPluginFactory GetPluginFactoryInternal(ClientClass)() nothrow @nogc 
{
    ScopedForeignCallback!(false, true) scopedCallback;
    scopedCallback.enter();
    auto client = mallocNew!ClientClass();

    return null;
}
